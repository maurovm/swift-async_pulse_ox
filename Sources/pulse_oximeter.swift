/**
 * \file    pulse_oximeter.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 21, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation
import CoreBluetooth
import AsyncBluetooth
import SensorRecordingUtils


/**
 * A single instance of a ASB_peripheral, representing a BLE-enabled
 * pulse oximeter. It abstracts common operations to perform on pulse oximeters
 */
final actor Pulse_oximeter
{
    
    @Published private(set) var central_manager_event: ASB_central_manager_event
    @Published private(set) var peripheral_event     : ASB_peripheral_event
    
    
    public init( _  device_identifier : Device.ID_type )
    {
        
        self.device_identifier = device_identifier
        
        central_manager  = ASB_central_manager()
        
        central_manager_event = central_manager.manager_event
        peripheral_event      = .no_set
        
    }
    
    
    // MARK: - Bluetooth life cycle management
    
    
    func is_bluetooth_powered_on() async throws
    {
        
        do
        {
            try await central_manager.wait_until_is_powered_on()
        }
        catch
        {
            throw Device.Connect_error.not_authorised(
                    device_id  : device_identifier
                )
        }
        
    }
    
    
    /**
     * Search and connect to a given BLE peripheral
     */
    func connect(
            _ peripheral_id : CBPeripheral.ID_type
        ) async throws
    {
        
        all_characteristics.removeAll()
        all_services.removeAll()
        active_peripheral = nil
        
        central_manager.$manager_event.assign(to: &$central_manager_event)
        
        guard let peripheral = try await scan_for_peripheral(with_ID: peripheral_id)
            else
            {
                throw Device.Connect_error.input_device_unavailable(
                    device_id  : device_identifier,
                    description: "Could not find peripheral with ID : " +
                                 "\(peripheral_id)"
                    )
            }
        
        do
        {
            
            try await central_manager.connect(peripheral)
            
            active_peripheral = peripheral
            active_peripheral?.$peripheral_event.assign(to: &$peripheral_event)
            
        }
        catch ASB_error.connection_in_progress
        {
            throw Device.Connect_error.input_device_unavailable(
                device_id  : device_identifier,
                description: "A previous connection is already in progress"
            )
        }
        catch ASB_error.failed_to_connect_to_peripheral(let error)
        {
            let message = error?.localizedDescription ?? "-"
        
            throw Device.Connect_error.input_device_unavailable(
                device_id  : device_identifier,
                description: "Peripheral \(peripheral.name) - error: " +
                             message
            )
        
        }
        catch
        {
            throw Device.Connect_error.input_device_unavailable(
                device_id  : device_identifier,
                description: "Connection failure for peripheral " +
                             "\(peripheral.name) - error: " +
                             error.localizedDescription
                )
        }
    
    }
    
    
    public func discover_services(
            _  service_UUIDs : [ CBService.ID_type]
        ) async throws
    {
        
        guard let peripheral = active_peripheral ,
              peripheral.is_connected
            else
            {
                throw Device.Connect_error.failed_to_connect_to_device(
                        device_id : device_identifier ,
                        description: "Is not connected"
                    )
            }
        
        
        do
        {
            all_services = try await peripheral.discover_services(service_UUIDs)
        }
        catch ASB_error.failed_to_discover_service(let error)
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                device_id  : device_identifier,
                description: "Cannot discover services: " +
                             error.localizedDescription
                )
        }
        catch
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                device_id  : device_identifier,
                description: "Cannot discover services: " +
                             error.localizedDescription
                )
        }
        
        
        if all_services.isEmpty
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                device_id  : device_identifier,
                description: "Cannot discover all services '\(service_UUIDs)'"
                )
        }
                
    }
    
    
    public func discover_characteristics(
            _    characteristic_UUIDs : [CBCharacteristic.ID_type],
            for  service_UUID         : CBService.ID_type
        ) async throws
    {
        
        guard let peripheral = active_peripheral ,
              peripheral.is_connected
            else
            {
                throw Device.Connect_error.failed_to_connect_to_device(
                        device_id : device_identifier ,
                        description: "Is not connected"
                    )
            }
        
        guard let service = all_services.first(where: {$0.id == service_UUID})
        else
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                device_id  : device_identifier,
                description: "Failed to obtain the BLE service with ID " +
                             "'\(service_UUID)' for peripheral " +
                             peripheral.name
                )
        }
        
        
        var discovered_characteristics : [CBCharacteristic] = []
        
        do
        {
            discovered_characteristics = try await peripheral.discover_characteristics(
                characteristic_UUIDs, for: service
                )
        }
        catch ASB_error.failed_to_discover_characteristics(let error)
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                device_id  : device_identifier,
                description: "Cannot discover characteristics for service " +
                             "\(service.name) from peripheral " +
                             peripheral.name + " : " +
                             error.localizedDescription
                )
        }
        catch
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                device_id  : device_identifier,
                description: "Cannot discover characteristics for service " +
                             "\(service.name) from peripheral " +
                             peripheral.name + " : "
                            + error.localizedDescription
                )
        }
        
        
        if discovered_characteristics.isEmpty
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                device_id  : device_identifier,
                description: "Cannot discover characteristics for service " +
                             "\(service.name) from peripheral " +
                             peripheral.name
                )
        }
        
        
        let new_characteristics = discovered_characteristics
            .filter { all_characteristics.contains($0) == false }
        
        all_characteristics.append(contentsOf: new_characteristics)
        
    }
    
    
    /**
     * Disconnect from the current active BLE peripheral
     */
    func disconnect() async throws
    {
        
        all_characteristics.removeAll()
        all_services.removeAll()
        
        guard let peripheral = active_peripheral ,
              peripheral.is_connected
            else
            {
                return
            }
        
        do
        {
            
            await peripheral.stop_notifications_from_all_characteristics()
            try await central_manager.disconnect(peripheral)
            active_peripheral = nil
            
        }
        catch ASB_error.no_connection_to_peripheral_exists
        {
            throw Device.Disconnect_error.failed_to_disconnect(
                device_id  : device_identifier,
                description: "Cannot disconnect from peripheral " +
                             peripheral.name + " : it is not connected"
                )
        }
        catch ASB_error.disconnecting_in_progress
        {
            throw Device.Disconnect_error.failed_to_disconnect(
                device_id  : device_identifier,
                description: "Cannot disconnect from peripheral " +
                             peripheral.name +
                             " : a disconnction is already in progress"
                )
        }
        catch
        {
            throw Device.Disconnect_error.failed_to_disconnect(
                device_id  : device_identifier,
                description: "Cannot disconnect from peripheral " +
                             peripheral.name + " : " +
                             error.localizedDescription
                )
        }
        
    }
    
    
    // MARK: - Notification subscriptions
    
    
    func notification_values(
            for  characteristic_id : CBCharacteristic.ID_type
        ) async throws -> AsyncThrowingStream<ASB_data, Error>
    {
        
        if let characteristic = all_characteristics.first(where: {$0.id == characteristic_id}) ,
           let peripheral = active_peripheral
        {
            return try await peripheral.notification_values(for: characteristic)
        }
        else
        {
            throw Device.Recording_error.failed_to_start(
                device_id  : device_identifier,
                description: "Couldn't not subscribe to notifications for " +
                             "characteristic \(characteristic_id)"
            )
        }
        
    }
    
    
    func stop_notifications(
            for  characteristic_id : CBCharacteristic.ID_type
        ) async throws
    {
        
        if let characteristic = all_characteristics.first(where: {$0.id == characteristic_id}) ,
           let peripheral = active_peripheral
        {
            if characteristic.isNotifying
            {
                await peripheral.stop_notifications(from: characteristic)
            }
        }
        else
        {
            throw Device.Recording_error.failed_to_stop(
                device_id  : device_identifier,
                description: "Couldn't not unsubscribe to notifications for " +
                             "characteristic \(characteristic_id)"
            )
        }
        
    }
    
    
    // MARK: - Public interface
    
    
    /**
     * Returns the list of label for all the configured and discovered
     * characteristics
     */
    public func get_configured_characteristics_labels() -> [CBCharacteristic.Label_type]
    {

        return all_characteristics.compactMap
                {
                    CBCharacteristic.get_label(for_UUID: $0.id)
                }
        
    }
    
    
    
    // MARK: - Private state

    
    private let device_identifier   : Device.ID_type
    private var central_manager     : ASB_central_manager
    private var active_peripheral   : ASB_peripheral?
    private var all_services        : [CBService] = []
    private var all_characteristics : [CBCharacteristic] = []
    
    
    // MARK: - Private interface
    
    
    private func scan_for_peripheral(
            with_ID  peripheral_id: CBPeripheral.ID_type
        ) async throws  -> ASB_peripheral?
    {
                
        var new_peripheral : ASB_peripheral? = nil
        
        do
        {
            
            let all_discovered_peripeherals = await central_manager.scan_for_peripherals()

            for try await peripheral in all_discovered_peripeherals
            {
                if Task.isCancelled
                {
                    break
                }
                
                if peripheral.id == peripheral_id
                {
                    new_peripheral = peripheral.peripheral
                    break
                }
            }
            
            await stop_scanning_for_peripherals()
            
        }
        catch let error as Device.Connect_error
        {
            await stop_scanning_for_peripherals()
            throw error
        }
        catch ASB_error.scanning_in_progress
        {
            await stop_scanning_for_peripherals()
            throw Device.Connect_error.input_device_unavailable(
                device_id  : device_identifier,
                description: "A previous scanning is already in progress"
            )
        }
        catch ASB_error.failed_to_scan_for_peripherals(let message)
        {
            await stop_scanning_for_peripherals()
            throw Device.Connect_error.input_device_unavailable(
                device_id  : device_identifier,
                description: "Could not discover BLE peripheral: " + message
            )
        }
        catch ASB_error.bluetoothUnavailable
        {
            await stop_scanning_for_peripherals()
            throw Device.Connect_error.authorisation_failure(
                device_id  : device_identifier,
                description: "Cannot access Bluetooth service"
            )
        }
        catch
        {
            await stop_scanning_for_peripherals()
            throw Device.Connect_error.input_device_unavailable(
                device_id  : device_identifier,
                description: "An error occurred while scanning for " +
                             "BLE peripheral: " + error.localizedDescription
            )
         
        }
        
        return new_peripheral
        
    }
    
    
    /**
     * Stop the scanning process
     */
    private func stop_scanning_for_peripherals() async
    {
        
        if central_manager.is_scanning
        {
            await central_manager.stop_scan()
        }
        
    }
    
}
