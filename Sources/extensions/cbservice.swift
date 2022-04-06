/**
 * \file    cbservice.swift
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
extension CBService
{
    
    /**
     * The classification of services we can read from
     */
    public enum Label_type
    {
        
        case device_information
        case heart_rate
        case battery
        case pulse_oximeter
        case nonin_oximetry
        
        
        public var description: String
        {
            switch self
            {
                case .device_information:
                    return "Device Information"
                case .heart_rate:
                    return "Heart Rate"
                case .battery:
                    return "Battery"
                case .pulse_oximeter:
                    return "Pulse Oximeter"
                case .nonin_oximetry:
                    return "Nonin Oximetry"
            }
        }
        
    }
    
    
    /**
     * The list of Service UUIDs that we can read data from
     */
    public static let ID_to_Label_mapping :
            [CBService.ID_type : CBService.Label_type] =
    [
        .init(string: "180A") : .device_information,
        .init(string: "180D") : .heart_rate,
        .init(string: "180F") : .battery,
        .init(string: "1822") : .pulse_oximeter,
        .init(string: "46A970E0-0D5F-11E2-8B5E-0002A5D5C51B"): .nonin_oximetry
    ]
    
    
    /**
     * The inverse mapping for the `ID_to_Label_mapping` dictionary.
     *
     * Returns: The unique CBUUID for a given service label. It returns
     *          nil if the label is not found
     */
    public static func get_UUID(
            for_label  label : CBService.Label_type
        ) -> CBService.ID_type?
    {
        
        return Self.ID_to_Label_mapping.first(where: {$1 == label })?.key
        
    }
    
    
    /**
     * Return the label for a given service UUID
     */
    public static func get_label(
            for_UUID service_id : CBService.ID_type
        ) -> CBService.Label_type?
    {
        
        return Self.ID_to_Label_mapping[service_id]
        
    }
    
    
    // MARK: - Instance properties
    
    
    /**
     * When the service's uuid is just a 4-code string, return a
     * more meaningful name in the format:
     *      [code] : [name]
     */
    var name : String
    {
        if let s_type = CBService.get_label(for_UUID: self.id)
        {
            return s_type.description + " : ( " + self.uuid.uuidString + ")"
        }
        else
        {
            return "\(self.uuid) : ( \(self.uuid.uuidString) )"
        }
    }
    
    
    /**
     * Return the type for this CBService
     */
    public var label : CBService.Label_type?
    {
        return Self.get_label(for_UUID: self.id)
    }
    
}
