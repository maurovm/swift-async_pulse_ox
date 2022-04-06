/**
 * \file    ble_bas_spec_decoder.swift
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
import AsyncBluetooth
import SensorRecordingUtils


/**
 * Bluetooth Low Energy decoder for Characteritic:
 *
 *   2A19: "Battery Level"
 *
 * Version 1.0 as published by the Bluetooth Standard on 2011/12/27
 * Check [https://www.bluetooth.com/specifications/specs] for the latest
 * information
 */
final class BLE_BAS_spec_decoder : BLE_decoder
{
    
    // MARK: - Characteristic identifiers
    
    
    /**
     * See ``BLE_decoder`` protocol for documentation
     */
    private(set) var id    : CBCharacteristic.ID_type = .init(string: "2A19")
    
    
    /**
     * See ``BLE_decoder`` protocol for documentation
     */
    private(set) var label : CBCharacteristic.Label_type = .battery_level
    
    
    // MARK: - Decoding raw BLE data
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     *
     * The battery level is given as a percentage in the first data byte
     */
    func decode(
            _ ble_data  : ASB_data
        ) throws -> BLE_spec_Output?
    {
        
        if ble_data.data.isEmpty
        {
            return nil
        }
        
        if ble_data.data.count < BLE_BAS_spec_decoder.minimum_packet_length
        {
            throw ASB_error.decode_data(
                    description: "Frame too small: only " +
                                 "\(ble_data.data.count) bytes received"
                )
        }
                
        return Output(
                timestamp          : ble_data.timestamp,
                battery_percentage : Int( ble_data.data[0] )
            )
        
    }
    
    
    // MARK: - BLE spec definitions
    
    
    /**
     * The data type that the `BLE` decodes
     */
    struct Output : BLE_spec_Output
    {
        
        let timestamp          : ASB_timestamp
        let battery_percentage : Int
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         */
        @inline(__always)
        func csv_value() -> String
        {
            return "\(timestamp),\(battery_percentage)\n"
        }
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         */
        @inline(__always)
        func value(
                _ signal_label : BLE_signal_type
            ) -> Int?
        {
            
            return (signal_label == .battery_percentage) ?
                battery_percentage : nil
            
        }

    }
    
    
    // MARK: - Public interface
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_csv_header() -> String
    {
        
        let battery_label = BLE_signal_type.battery_percentage.short_name
        
        return "Timestamp,\(battery_label)\n"
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_info_description() -> String
    {
        
        let signals_description = get_description_for_signals(
                [.battery_percentage]
            )
        
        let info : String =
            """
            \(output_info_description_heder)
            Timestamp , "Unix epoch" , nanoseconds , ,
            \(signals_description)
            """
        
        return info
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_empty_value() -> BLE_spec_Output
    {
        
        return Output(
            timestamp          : 0,
            battery_percentage : 0
        )
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func get_minimum_numerics() -> [BLE_signal]
    {
        
        var signal_list : [BLE_signal] = []
        
        if let signal = get_signal( .battery_percentage )
        {
            signal_list.append(signal)
        }
        
        return signal_list
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func get_signal(
            _ signal_type : BLE_signal_type
        ) -> BLE_signal?
    {
        
        let signal : BLE_signal?
        
        switch signal_type
        {
                
            case .battery_percentage:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "%",
                    gain      : 1,
                    frequency : 1,
                    value     : 0
                )
                
            default:
                signal = nil
        }
        
        return signal
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * Every data frame sent by Nonin should have this number of bytes
     */
    private static let minimum_packet_length : Int = 1

}
