/**
 * \file    recording_settings.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 18, 2022
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
 * Settings for the Nonin pulse oximeters
 */
final class Recording_settings : Device_settings
{
    
    
    // MARK: - Properties that represent module settings
    
    
    /**
     * The unique ID for configured BLE peripheral
     */
    var peripheral_id : CBPeripheral.ID_type?
    {
        get
        {
            if let key_value = store.string(forKey: peripheral_id_key)
            {
                return UUID(uuidString: key_value)
            }
            else
            {
                return nil
            }
        }
        
        set(new_value)
        {
            if let key_value = new_value
            {
                store.set(key_value.uuidString, forKey: peripheral_id_key)
            }
            else
            {
                remove_value(forKey: peripheral_id_key)
            }
        }
    }
    
    
    /**
     * The unique name for configured BLE peripheral
     */
    var peripheral_name : String?
    {
        get
        {
            return store.string(forKey: peripheral_name_key)
        }
        
        set(new_value)
        {
            if let key_value = new_value
            {
                store.set(key_value, forKey: peripheral_name_key)
            }
            else
            {
                remove_value(forKey: peripheral_name_key)
            }
        }
    }
    
    
    /**
     * The string to search for BLE peripherals
     */
    var peripheral_name_filter : String
    {
        get
        {
            if let key_value = store.string(forKey: peripheral_name_filter_key)
            {
                return key_value
            }
            else
            {
                return ""
            }
        }
        
        set(new_value)
        {
            store.set(new_value, forKey: peripheral_name_filter_key)
        }
    }
    
    
    /**
     * All the services and characteristics configured to record data from
     */
    var characteristics: [CBService.ID_type : [CBCharacteristic.ID_type]]
    {
        get
        {
            let key_value = store.object(forKey: characteristics_key) as?
                    [String:String] ?? [:]
            
            return string_to_characteristics(key_value)
            
        }
        
        set(new_value)
        {
            if new_value.isEmpty
            {
                remove_value(forKey: characteristics_key)
            }
            else
            {
                let key_value = characteristics_to_string(new_value)
                store.set(key_value, forKey: characteristics_key)
            }
            
        }
    }
    
    
    /**
     * Type innitialiser
     */
    init()
    {
        
        let key_prefix = "pulseox_"
        
        peripheral_id_key          = key_prefix + "peripheral_UUID"
        peripheral_name_key        = key_prefix + "peripheral_name"
        peripheral_name_filter_key = key_prefix + "peripheral_name_filter"
        characteristics_key        = key_prefix + "characteristics_UUIDs"
        
        super.init(key_prefix: key_prefix)
        
    }
    
    
    // MARK: - Private state
    
    
    private let peripheral_id_key          : String
    private let peripheral_name_key        : String
    private let peripheral_name_filter_key : String
    private let characteristics_key        : String
    
    
    /**
     * Character used to serialise to the UserDefaults storage the array of
     * characteristic IDS selected
     */
    private let separator : Character = "|"
    
    
    // MARK: - Private interface
    
    
    private func remove_value(forKey key : String)
    {
        
        if store.object(forKey: key) != nil
        {
            store.removeObject(forKey: key)
        }
        
    }
    
    
    /**
     *  Converts a dictionary from the format:
     *
     *          [ CBService.ID_type : [CBCharacteristic.ID_type] ]
     *
     *  into a flatten string format:
     *
     *          [String : String]
     */
    private func characteristics_to_string(
            _  input : [ CBService.ID_type : [CBCharacteristic.ID_type] ]
        ) -> [String : String]
    {
        
        var output : [String : String] = [:]
        
        for (service_id, characteristic_IDs) in input
        {
            let key   = service_id.uuidString
            let value = characteristic_IDs
                .map { $0.uuidString }
                .joined(separator: String(separator))
            
            output[key] = value
        }
        
        return output
        
    }
    
    
    /**
     *  Converts a dictionary from the format:
     *
     *          [String : String]
     *
     *  into a dictionary of CBUUID arrayss:
     *
     *          [ CBService.ID_type : [CBCharacteristic.ID_type] ]
     */
    private func string_to_characteristics(
            _  input : [String : String]
        ) -> [ CBService.ID_type : [CBCharacteristic.ID_type] ]
    {
        
        var output : [ CBService.ID_type : [CBCharacteristic.ID_type] ] = [:]
    
        for (key, value) in input
        {
            let service_id = CBUUID(string: key)
            
            let characteristic_IDs = value.split(separator: separator)
                .map(String.init)
                .map{ CBUUID(string: $0) }
            
            output[service_id] = characteristic_IDs
        }
        
        return output
        
    }
    
}
