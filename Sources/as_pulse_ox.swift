/**
 * \file    as_pulse_ox.swift
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
 * Global camera constants and utility methods
 */
public struct AS_pulse_ox
{
    
    // MARK: - Public utility methods
    
    
    /**
     * Objects outside the module can create instances of this class
     */
    public init()
    {
    }
    
    
    /**
     * Verifies if we can record from the BLE Services and Characteristics
     * the user configured for the application
     *
     * Returns:  .success : if we can record from all the configured
     *           services and characterisitcs
     *
     *           .failure : if errors exits, `Nonin_error` contains more
     *           details about the nature of the error
     */
    public static func is_recording_supported() -> Result<Void, Pulse_ox_error>
    {
        
        let settings = Recording_settings()
        let characteristics = settings.characteristics
        
        return is_recording_supported(for_UUIDs: characteristics)
        
    }
    
    
    /**
     * Check if the app has access to the bluetooth service
     * This methods is not static because we need to make sure the Central
     * Manager does not leak
     */
    public func can_access_bluetooth() async -> Bool
    {
        
        let central_manager = ASB_central_manager()

        // Sleep for a while, waiting for the central manager to come alive
        do
        {
            try await Task.sleep(seconds: 0.2)
        }
        catch
        {
            // continue as normal if the timer gets cancelled
        }
        
        let status: Bool
        
        do
        {
            try await central_manager.wait_until_is_powered_on()
            status = true
        }
        catch
        {
            status = false
        }
        
        return status
        
    }
    
    
    // MARK: - Known UUIDs for supported services/characteristics
    
    
    /**
     * The list of services we can record data from
     */
    static let supported_services : [CBService.Label_type] =
        [
            .nonin_oximetry ,
            .battery
        ]
    
    /**
     * The list of characteristics we can record data from
     *
     * The order of this array will determine which characteristic
     * we display data in the UI
     */
    static let supported_characteristics: [CBCharacteristic.Label_type] =
        [
            .nonin_continuous_oximetry,
            .nonin_pulse_interval_time,
            .nonin_device_status,
            .nonin_PPG ,
            .battery_level
        ]

    
    // MARK: - Utility methods internal to the AsyncPulseOx module
    
    
    /**
     * Verifies if we can record from CBUUIs in the input dictionary,
     * representing an array of characteristic_ids per service_id. An example
     * of this dictionary is the `Nonint_settings.characteristics` property,
     * that has the sevices and characteristics a user configured for the
     * application
     *
     * Parameter  for_UUIDs : A dictionary that contains the list of
     *               characterisitics per service_id. In the format:
     *
     *         [ service_id :  [characteristic_ids] ]
     *
     * Returns:  .success : if we can record from all the services and
     *           characterisitcs in the input dictionary
     *
     *           .failure : if errors exits, `Nonin_error` contains more
     *           details about the nature of the error
     */
    static func is_recording_supported(
        for_UUIDs  uuid_map : [CBService.ID_type : [CBCharacteristic.ID_type] ]
        ) -> Result<Void, Pulse_ox_error>
    {
        
        if uuid_map.isEmpty
        {
            return .failure( .empty_configuration )
        }
        
        
        //
        // Check if there are service_ids without characteristics
        //
        
        
        let empty_service_UUIDs = uuid_map
            .reduce( into: [CBService.ID_type: Int]() )
            {
                // Reduce to a new dictionary containing the count of
                // characteristics per service_id
                
                output, uuid_map_tuple in
                
                let service_id = uuid_map_tuple.key
                let number_of_characteristics = uuid_map_tuple.value.count
                
                output[service_id] = number_of_characteristics
            }
            .filter { $0.value == 0 }
            .map    { $0.key }
        
        
        if empty_service_UUIDs.count > 0
        {
            let id_list = CBUUID_array_to_string(empty_service_UUIDs)
            return .failure(.no_characteristics_configured("[ \(id_list) ]"))
        }
        
        
        //
        // Check for services we can't map their labels
        //
        
        
        let service_UUIDs = uuid_map.keys
        
        let unknown_service_UUIDs = service_UUIDs.map{$0}
            .filter { CBService.get_label(for_UUID: $0) == nil }

        
        if unknown_service_UUIDs.count > 0
        {
            let id_list = CBUUID_array_to_string(unknown_service_UUIDs)
            return .failure(.services_not_supported("[ \(id_list) ]"))
        }
            
        
        //
        // Check for services we cannot record data from
        //

        
        let unsupported_service_UUIDs = service_UUIDs
            .compactMap { CBService.get_label(for_UUID: $0) }
            .filter     { Self.supported_services.contains($0) == false }
            .compactMap { CBService.get_UUID(for_label: $0) }

        
        if unsupported_service_UUIDs.count > 0
        {
            let id_list = CBUUID_array_to_string(unsupported_service_UUIDs)
            return .failure(.services_not_supported("[ \(id_list) ]"))
        }
        
        
        //
        // Check for characteristics we can't mape their labels
        //
        
        
        let characteristic_UUIDs = uuid_map.values.flatMap{$0}
        
        let unknown_characteristic_UUIDs = characteristic_UUIDs
            .filter { CBCharacteristic.get_label(for_UUID: $0) == nil }

        
        if unknown_characteristic_UUIDs.count > 0
        {
            let id_list = CBUUID_array_to_string(unknown_characteristic_UUIDs)
            return .failure(.characteristics_not_supported("[ \(id_list) ]"))
        }
        
        
        //
        // Check for characteristics we cannot record data from
        //
        
        
        let unsupported_characteristic_UUIDs = characteristic_UUIDs
            .compactMap { CBCharacteristic.get_label(for_UUID: $0) }
            .filter     { Self.supported_characteristics.contains($0) == false }
            .compactMap { CBCharacteristic.get_UUID(for_label: $0) }

        
        if unsupported_characteristic_UUIDs.count > 0
        {
            let id_list = CBUUID_array_to_string(unsupported_characteristic_UUIDs)
            return .failure(.characteristics_not_supported("[ \(id_list) ]"))
        }
        
        return .success( () )
        
    }
    
    
    
    // MARK: - Private utiliy methods
    
    
    private static func CBUUID_array_to_string(
            _ input : [CBUUID]
        ) -> String
    {
        return input
            .map { "'(\($0.uuidString)) : \($0)'" }
            .joined(separator: " , ")
    }
    
}
