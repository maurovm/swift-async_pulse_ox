/**
 * \file    configure_bluetooth_model.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 24, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import CoreBluetooth
import AsyncBluetooth
import SensorRecordingUtils


/**
 * ViewModel for the view to select to which Nonin device to connect
 */
@MainActor
public final class Configure_bluetooth_model : ObservableObject
{
    
    private(set) var setup_error: ASB_error?
    
    
    // MARK: - Properties for the peripheral
    
    
    @Published private(set) var connecting_to_peripheral     = false
    
    @Published private(set) var disconnecting_to_peripheral  = false
    
    /**
     * Are we currently scanning for BLE devices?
     */
    @Published private(set) var is_scanning_for_peripherals = false
    
    /**
     * All the BLE devices discovered in realtime
     */
    @Published private(set) var all_peripherals: [ASB_peripheral] = []
    
    /**
     * the peripheral the user chose to view details
     */
    @Published private(set) var active_peripheral : ASB_peripheral?
    
    /**
     * The peripherals that the user chose to use to record from.
     * This could be different from the peripheral being inspected for
     * information
     *
     * For now, we only allow the selection of 1 device
     */
    @Published private(set) var selected_peripheral_id : UUID?
    
    /**
     * The name of the selected peripheral
     */
    @Published private(set) var selected_peripheral_name : String?
    
    
    /**
     * The string to search for BLE peripherals
     */
    @Published var peripheral_name_filter : String = ""
    
    
    // MARK: - Properties for services
    
    
    /**
     * Are we currently scanning for services?
     */
    @Published private(set) var searching_for_services = false
    
    @Published private(set) var all_services: [CBService] = []
    
    @Published private(set) var active_service: CBService?
    
    
    // MARK: - Properties for characteristics
    
    
    /**
     * Are we currently scanning for characteristics?
     */
    @Published private(set) var searching_for_characteristics = false
    
    @Published private(set) var all_characteristics : [CBCharacteristic] = []
    
    @Published private(set) var active_characteristic: CBCharacteristic?
    
    
    @Published private(set) var all_selected_characteristics
    : [ CBService.ID_type : [CBCharacteristic.ID_type] ] = [:]
    
    
    // MARK: - Properties for descriptors
    
    
    /**
     * Are we currently scanning for descriptors?
     */
    @Published private(set) var searching_for_descriptors = false
    
    @Published private(set) var all_descriptors : [CBDescriptor] = []
    
    @Published private(set) var active_descriptor : CBDescriptor?
    
    
    public var recording_support_error : String = ""
    
    
    // MARK: - Class initialisation
    
    
    /**
     * Class initialiser
     */
    public init()
    {
//        print("Configure_bluetooth_model : init called")
        
        central_manager = ASB_central_manager()
        
        // Load selected data from the User configuration settings
        
        load_settings()
        
        all_descriptors.removeAll()
        all_characteristics.removeAll()
        all_services.removeAll()
        all_peripherals.removeAll()
    }
    
    /**
     * Clean up resources
     */
    deinit
    {
        
//        print("Configure_bluetooth_model : deinit called")
        
        scanning_task?.cancel()
        scanning_task = nil
        stop_scanning_task?.cancel()
        stop_scanning_task = nil
        
        Task
        {
            [weak self] in
            await self?.disconnect_from_active_peripheral()
        }
        
    }
    
    
    // MARK: - Public interface
    
    
    public func save_peripheral_name_filter()
    {
        
        settings.peripheral_name_filter = peripheral_name_filter
        
    }
    
    
    // MARK: - Start scanning for peripherals
    
    
    /**
     * Discover all the bluetooth peripherals nearby and add them to the
     * available array if they are Nonin devices
     */
    public func start_scanning() async -> Bool
    {
        
        var success = false
        
        is_scanning_for_peripherals = true
        
        do
        {
            
            try await central_manager.wait_until_is_powered_on()
            
            for try await peripheral in await central_manager.scan_for_peripherals()
            {
                if Task.isCancelled
                {
                    break
                }
                
                if all_peripherals.contains(peripheral.peripheral) == false
                {
                    all_peripherals.append(peripheral.peripheral)
                }
            }
            
            await stop_scanning()
            
            success = true
            
        }
        catch let error as ASB_error
        {
            await stop_scanning()
            setup_error = error
        }
        catch
        {
            await stop_scanning()
            setup_error = ASB_error.unknown_error(
                description: "Error scanning for peripherals: " +
                             error.localizedDescription
                )
        }
        
        return success
        
    }
    
    /**
     * Stop the scanning process
     */
    private func stop_scanning() async
    {
        
        if central_manager.is_scanning
        {
            await central_manager.stop_scan()
        }
        
        is_scanning_for_peripherals = false
        
    }
    
    
    // MARK: - Peripheral connection
    
    
    public func connect_to_peripheral(
            _ id : UUID
        ) async -> Bool
    {
        
        if let connected_device = active_peripheral ,
           connected_device.id != id
        {
            if await disconnect_from_peripheral(connected_device.id) == false
            {
                return false
            }
        }
        
        guard let peripheral = all_peripherals.first(where: {$0.id == id})
            else
            {
                return false
            }
        
        defer
        {
            connecting_to_peripheral = false
        }
        
        active_peripheral = peripheral
        connecting_to_peripheral = true
        
        active_descriptor     = nil
        active_characteristic = nil
        active_service        = nil
        
        all_descriptors.removeAll()
        all_characteristics.removeAll()
        all_services.removeAll()
        
        
        var success = false
        
        do
        {
            
            try await central_manager.connect(peripheral)
            connecting_to_peripheral = false
            
            success = await discover_services(for: peripheral)
            
        }
        catch let error as ASB_error
        {
            setup_error = error
        }
        catch
        {
            setup_error = ASB_error.unknown_error(
                    description: "Failed to connect to peripheral: " +
                                error.localizedDescription
                )
        }
        
        return success
        
    }
    
    
    public func disconnect_from_peripheral(
            _ id : UUID
        ) async -> Bool
    {
        
        guard let peripheral = all_peripherals.first(where: {$0.id == id})
            else
            {
                return false
            }
        
        defer
        {
            active_descriptor     = nil
            active_characteristic = nil
            active_service        = nil
            active_peripheral     = nil
            
            disconnecting_to_peripheral = false
        }
        
        disconnecting_to_peripheral = true
        
        var success = false
        
        do
            
        {

            try await central_manager.disconnect(peripheral)
            
            success = true
            
        }
        catch ASB_error.no_connection_to_peripheral_exists
        {
            setup_error = ASB_error.no_connection_to_peripheral_exists
        }
        catch ASB_error.disconnecting_in_progress
        {
            setup_error = ASB_error.disconnecting_in_progress
        }
        catch
        {
            setup_error = ASB_error.unknown_error(
                    description: "Failed to disconnect from peripheral: " +
                                 error.localizedDescription
                )
        }
        
        return success
        
    }
    
    
    public func disconnect_from_active_peripheral() async -> Bool
    {
        
        var success = true
        
        if let peripheral = active_peripheral
        {
            
//            print("Configure_bluetooth_model : About to disconnect from active periphearl")
            
            success = await disconnect_from_peripheral(peripheral.id)
        }
        
        return success
        
    }
    
    
    // MARK: - Discovering services, characteristics and descriptors
    
    
    public func discover_services(
            for  peripheral : ASB_peripheral
        ) async -> Bool
    {
        
        defer
        {
            searching_for_services = false
        }
        
        active_peripheral = peripheral
        searching_for_services = true
        
        active_descriptor     = nil
        active_characteristic = nil
        active_service        = nil
    
        all_descriptors.removeAll()
        all_characteristics.removeAll()
        all_services.removeAll()
        
        //show_peripheral_info(peripheral)
        
        var success = false
        
        do
        {
            
            all_services = try await peripheral.discover_services()
            
            success = true
            
        }
        catch let error as ASB_error
        {
            setup_error = error
        }
        catch
        {
            setup_error = ASB_error.failed_to_discover_service(error)
        }
        
        return success
        
    }
    
    public func discover_characteristics(
            for  service : CBService
        ) async -> Bool
    {
        
        guard let peripheral = active_peripheral
            else
            {
                return false
            }
        
        defer
        {
            searching_for_characteristics = false
        }
        
        searching_for_characteristics = true
        active_service = service
        
        active_descriptor     = nil
        active_characteristic = nil
        
        all_descriptors.removeAll()
        all_characteristics.removeAll()
        
        
        var success = false
        
        do
        {
            
            all_characteristics = try await peripheral.discover_characteristics(
                    nil, for: service
                )
            
            success = true
            
        }
        catch let error as ASB_error
        {
            setup_error = error
            active_service = nil
        }
        catch
        {
            setup_error = ASB_error.unknown_error(
                description: "Failed to discover characteristic for service: " +
                             error.localizedDescription
            )
            active_service = nil
        }
        
        return success
        
    }
    
    
    public func discover_descriptors(
            for  characteristic : CBCharacteristic
        ) async -> Bool
    {
        
        guard let peripheral = active_peripheral
            else
            {
                return false
            }
        
        defer
        {
            searching_for_descriptors = false
        }
        
        searching_for_descriptors = true
        active_characteristic = characteristic
        
        active_descriptor     = nil
        
        all_descriptors.removeAll()
        
        //show_characteristic_info(characteristic)
        
        var success = false
        
        do
        {
            
            all_descriptors = try await peripheral.discover_descriptors(
                    for: characteristic
                )
            
            success = true
            
        }
        catch let error as ASB_error
        {
            setup_error = error
        }
        catch
        {
            setup_error = ASB_error.unknown_error(
                    description: "Failed to discover descriptor " +
                                 "for characteristic: " +
                                 error.localizedDescription
                )
        }
        
        return success
        
    }
    
    
    // MARK: - Toggle selection of objects
    
    
    public func is_active_peripheral_selected() -> Bool
    {
        var exists = false
        
        if let active_peripheral_id = active_peripheral?.id
        {
            exists = is_peripheral_selected(active_peripheral_id)
        }
        
        return exists
    }
    
    public func is_peripheral_selected(
            _  peripheral_id  : CBPeripheral.ID_type
        ) -> Bool
    {
        var exists = false
        
        if let selected_id = selected_peripheral_id ,
           (selected_id == peripheral_id)
        {
            exists = true
        }
        
        return exists
    }
    
    
    public func is_active_service_selected() -> Bool
    {
        var exists = false
        
        if let active_service_id = active_service?.id
        {
            exists = is_service_selected(active_service_id)
        }
        
        return exists
    }
    
    /**
     * Check if a given service is selected for the current active peripheral
     */
    public func is_service_selected(
        _   service_id : CBService.ID_type
        ) -> Bool
    {
        var is_selected = false
        
        if is_active_peripheral_selected()    &&
           all_selected_characteristics.keys.contains(service_id)
        {
            is_selected = true
        }
        
        return is_selected
    }
    
    
    /**
     * Check if a given characteristic is selected for the current
     * active service and peripheral
     */
    public func is_characteristic_selected(
        _   characteristic_id : CBCharacteristic.ID_type
        ) -> Bool
    {
        var is_selected = false
        
        if is_active_peripheral_selected()  &&  is_active_service_selected()
        {
            if  let service_id = active_service?.id ,
                let characteristics = all_selected_characteristics[service_id] ,
                characteristics.contains(characteristic_id)
            {
                is_selected = true
            }
        }
        
        return is_selected
    }
    
    
    public func clear_all_selections()
    {
        
        all_selected_characteristics.removeAll()
        selected_peripheral_id   = nil
        selected_peripheral_name = nil
        
    }
    
    
    public func toggle_selection_for_characteristic(
            _  characteristic_id : CBCharacteristic.ID_type
        )
    {
        
        if let service_id = active_service?.id   ,
           is_characteristic_selected(characteristic_id)
        {
            
            // If the characteristic is already selected, we need to
            // remove it and clear all dependants if needed
            
            all_selected_characteristics[service_id]?.removeAll(
                    where: {$0 == characteristic_id}
                )
            
            // Remove the key if no more characteristics are selected for the
            // service
            
            if let elements = all_selected_characteristics[service_id] ,
               elements.count == 0
            {
                all_selected_characteristics.removeValue(forKey: service_id)
            }
            
            // If no more services selected, unselect the peripheral
            
            if all_selected_characteristics.isEmpty
            {
                clear_all_selections()
            }
            
        }
        else if let service_id = active_service?.id ,
                is_active_peripheral_selected()
        {
            
            // We need to add the characteristic for the current active
            // service
            
            if all_selected_characteristics.keys.contains(service_id)
            {
                all_selected_characteristics[service_id]?.append(characteristic_id)
            }
            else
            {
                all_selected_characteristics[service_id] = [characteristic_id]
            }
            
        }
        else if let service_id      = active_service?.id      ,
                let peripheral_id   = active_peripheral?.id   ,
                let peripheral_name = active_peripheral?.name ,
                is_active_peripheral_selected() == false
        {
            
            // The active peripheral and service are not selected
            // Remove all previoys selection and select them
            
            clear_all_selections()
            
            selected_peripheral_id   = peripheral_id
            selected_peripheral_name = peripheral_name
            all_selected_characteristics[service_id] = [characteristic_id]
        }
        
    }
    
    
    // MARK: - Saving selections to UserDefaults
    
    
    public func is_selection_empty() -> Bool
    {
        
        return (selected_peripheral_id == nil)  ||
               (all_selected_characteristics.isEmpty)
        
    }
    
    
    public func is_recording_supported() -> Bool
    {
        
        var supported : Bool = true
        
        let result = AS_pulse_ox.is_recording_supported(
                for_UUIDs: all_selected_characteristics
            )
        
        switch result
        {
            case .success():
                recording_support_error = ""
                supported = true
                
            case .failure(let error):
                switch error
                {
                    case .empty_configuration:
                        recording_support_error = "Selection is empty"
                        
                    case .services_not_supported(let services):
                        recording_support_error = "\(services)"
                        
                    case .characteristics_not_supported(let characteristics):
                        recording_support_error = "\(characteristics)"
                        
                    case .no_characteristics_configured(let services):
                        recording_support_error = "\(services)"
                }
                supported = false
        }
        
        return supported
        
    }
    
    
    public func save_settings()
    {
        
        settings.peripheral_id   = selected_peripheral_id
        settings.peripheral_name = selected_peripheral_name
        settings.characteristics = all_selected_characteristics
        
    }
    
    
    private func load_settings()
    {
        
        selected_peripheral_id       = settings.peripheral_id
        selected_peripheral_name     = settings.peripheral_name
        all_selected_characteristics = settings.characteristics
        peripheral_name_filter       = settings.peripheral_name_filter
        
    }
    
    
    // MARK: - Private state

    
    private var settings = Recording_settings()
    
    /**
     * Our own object that manages the Bluetooth stack
     */
    private var central_manager:ASB_central_manager
    
    private var scanning_task : Task<Void, Never>? = nil
    
    private var stop_scanning_task : Task<Void, Never>? = nil
    
    
}
