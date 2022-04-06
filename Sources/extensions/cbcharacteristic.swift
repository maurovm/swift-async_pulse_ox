/**
 * \file    cbcharacteristic.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 10, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation
import CoreBluetooth


/**
 * Additional methods to the CoreBluetooth's Characteristic
 */
extension CBCharacteristic
{
    
    /**
     * The classification of characteristics we can read from
     */
    public enum Label_type : String
    {
        
        case battery_level
        case system_id
        case model_number_string
        case serial_number_string
        case firmware_revision_string
        case hardware_revision_string
        case software_revision_string
        case manufacturer_name_string
        case ieee_11073_20601
        case heart_rate
        case PLX_continuous_measurement
        case PLX_features
        case nonin_continuous_oximetry
        case nonin_pulse_interval_time
        case nonin_control_point
        case nonin_PPG
        case nonin_memory_playback
        case nonin_device_status
        
        
        public var description: String
        {
            switch self
            {
                case .battery_level:
                    return "Battery Level"
                case .system_id:
                    return "System ID"
                case .model_number_string:
                    return "Model Number String"
                case .serial_number_string:
                    return "Serial Number String"
                case .firmware_revision_string:
                    return "Firmware Revision String"
                case .hardware_revision_string:
                    return "Hardware Revision String"
                case .software_revision_string:
                    return "Software Revision String"
                case .manufacturer_name_string:
                    return "Manufacturer Name String"
                case .ieee_11073_20601:
                    return "IEEE 11073-20601 Regulatory Certification Data List"
                case .heart_rate:
                    return "Heart Rate Measurement"
                case .PLX_continuous_measurement:
                    return "PLX Continuous Measurement"
                case .PLX_features:
                    return "PLX Features"
                case .nonin_continuous_oximetry:
                    return "Nonin Continuous Oximetry"
                case .nonin_pulse_interval_time:
                    return "Nonin Pulse Interval Time"
                case .nonin_control_point:
                    return "Nonin Control Point"
                case .nonin_PPG:
                    return "Nonin_PPG"
                case .nonin_memory_playback:
                    return "Nonin Memory Playback"
                case .nonin_device_status:
                    return "Nonin Device Status"
            }
        }
    }

    
    /**
     * The mapping between known CBUUIDs and Characteristic types
     * we can read data from
     */
    public static let ID_to_Label_mapping :
            [CBCharacteristic.ID_type : CBCharacteristic.Label_type] =
    [
        .init(string: "2A19") : .battery_level,
        .init(string: "2A23") : .system_id,
        .init(string: "2A24") : .model_number_string,
        .init(string: "2A25") : .serial_number_string,
        .init(string: "2A26") : .firmware_revision_string,
        .init(string: "2A27") : .hardware_revision_string,
        .init(string: "2A28") : .software_revision_string,
        .init(string: "2A29") : .manufacturer_name_string,
        .init(string: "2A2A") : .ieee_11073_20601,
        .init(string: "2A37") : .heart_rate,
        .init(string: "2A5F") : .PLX_continuous_measurement,
        .init(string: "2A60") : .PLX_features,
        .init(string: "0AAD7EA0-0D60-11E2-8E3C-0002A5D5C51B"): .nonin_continuous_oximetry,
        .init(string: "34E27863-76FF-4F8E-96F1-9E3993AA6199"): .nonin_pulse_interval_time,
        .init(string: "1447AF80-0D60-11E2-88B6-0002A5D5C51B"): .nonin_control_point,
        .init(string: "EC0A883A-4D24-11E7-B114-B2F933D5FE66"): .nonin_PPG,
        .init(string: "EC0A8DDA-4D24-11E7-B114-B2F933D5FE66"): .nonin_memory_playback,
        .init(string: "EC0A9302-4D24-11E7-B114-B2F933D5FE66"): .nonin_device_status
    ]
    
    
    /**
     * The inverse mapping for the `ID_to_Label_mapping` dictionary.
     *
     * Returns: The unique CBUUID for a given characteristic label. It returns
     *          nil if the label is not found
     */
    public static func get_UUID(
            for_label  label : CBCharacteristic.Label_type
        ) -> CBCharacteristic.ID_type?
    {
        
        return Self.ID_to_Label_mapping.first(where: {$1 == label })?.key
        
    }
    
    
    /**
     * Return the label for a given characteristic UUID
     */
    public static func get_label(
            for_UUID characteristic_id : CBCharacteristic.ID_type
        ) -> CBCharacteristic.Label_type?
    {
        
        return Self.ID_to_Label_mapping[characteristic_id]
        
    }
    
    
    // MARK: - Instance properties
    
    
    /**
     * When the characteristic's uuid is just a 4-code string, return a
     * more meaningful name in the format:
     *      [code] : [name]
     */
    var name : String
    {
        if let c_type = CBCharacteristic.get_label(for_UUID: self.id)
        {
            return c_type.description + " : ( " + self.uuid.uuidString + ")"
        }
        else
        {
            return "\(self.uuid) : ( \(self.uuid.uuidString) )"
        }
    }
    
    
    /**
     * return the `Label_type` for this characteristic
     */
    var label : CBCharacteristic.Label_type?
    {
        return Self.get_label(for_UUID: self.id)
    }
    
}
