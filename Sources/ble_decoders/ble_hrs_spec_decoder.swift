/**
 * \file    ble_hrs_spec_decoder.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 8, 2022
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
 *   2A37 : "Hearr Rate Measurement"
 *
 * Version 1.0 as published by the Bluetooth Standard on 2011/07/12
 * Check [https://www.bluetooth.com/specifications/specs] for the latest
 * information
 */
final class BLE_HRS_spec_decoder : BLE_decoder
{
    
    // MARK: - Characteristic identifiers
    
    
    /**
     * See ``BLE_decoder`` protocol for documentation
     */
    private(set) var id    : CBCharacteristic.ID_type = .init(string: "2A37")
    
    
    /**
     * See ``BLE_decoder`` protocol for documentation
     */
    private(set) var label : CBCharacteristic.Label_type = .heart_rate
    
    
    // MARK: - Decoding raw BLE data
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     *
     * The first data byte is the flags that describe:
     *
     *  - If the heart rate is stored as either 8-bit or 16-bit.
     *  - If 16-bit R_R intervals are present. If so, there can be any number
     *    of them
     *
     * The R_R intervals are returned in milliseconds
     */
    func decode(
            _ ble_data : ASB_data
        ) throws -> BLE_spec_Output?
    {
        
        if ble_data.data.isEmpty
        {
            return nil
        }
        
        let data = ble_data.data
        
        // Decode Heart rate
        
        let flags = Status(rawValue: data[0])
        
        var data_index : Int
        let hr_value   : Int
        
        if flags.contains(.HR_16_bit)
        {
            if data.count > 1
            {
                hr_value = (Int(data[2]) << 8) + Int(data[1])
                data_index = 3
            }
            else
            {
                throw ASB_error.decode_data(
                        description: "HR 16-bit value not present"
                    )
            }
        }
        else
        {
            if data.count > 1
            {
                hr_value = Int(data[1])
                data_index = 2
            }
            else
            {
                throw ASB_error.decode_data(
                        description: "HR 8-bit value not present"
                    )
            }
        }
        
        // Decode all 16-bit R-R intervals
        
        var rr_interval_values     : [Int]
        
        if flags.contains(.RR_interval)
        {
            let number_of_rr_intervals : Int = (data.count - data_index) / 2
            
            if number_of_rr_intervals > Self.max_number_of_rr_intervals
            {
                throw ASB_error.decode_data(
                    description: "\(number_of_rr_intervals) RR intervals " +
                                 "recived, the maximum allowed is " +
                                 "\(Self.max_number_of_rr_intervals)"
                    )
            }
            
            rr_interval_values = Array(
                    repeating: 0, count: number_of_rr_intervals
                )
            
            var rr_index = 0
            for i in stride(from: data_index, to: data.count, by: 2)
            {
                rr_interval_values[rr_index] =
                        (Int(data[i+1]) << 8) + Int(data[i])
                
                rr_index += 1
            }
        }
        else
        {
            rr_interval_values = []
        }
        
        return Output(
                timestamp   : ble_data.timestamp,
                HR          : hr_value,
                RR_interval : rr_interval_values
            )
        
    }
    
    
    // MARK: - BLE spec definitions
    
    
    /**
     * The data type that the `BLE` decodes
     *
     * Units:
     *  - HR           : beats per minute (bpm)
     *  - R_R interval : milliseconds
     */
    struct Output : BLE_spec_Output
    {
        
        let timestamp   : ASB_timestamp
        let HR          : Int
        let RR_interval : [Int]
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         */
        @inline(__always)
        func csv_value() -> String
        {
            
            // Convert all the RR intervals into a single string
            
            let RR_intervals_value = RR_interval.map{ "\($0)" }
                .joined(separator: ",")
            
            // Append extra "," if needed to fill the empty columns
            
            let current_pulse_columns = RR_interval.count
            
            let num_of_empty_columns =
                BLE_HRS_spec_decoder.max_number_of_rr_intervals -
                current_pulse_columns
            
            let extra_csv_separators = (num_of_empty_columns > 0) ?
                String(repeating: ",", count: num_of_empty_columns) : ""
            
            return "\(timestamp),\(HR),\(RR_intervals_value)\(extra_csv_separators)\n"
            
        }
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         */
        @inline(__always)
        func value(
                _ signal_label : BLE_signal_type
            ) -> Int?
        {
            
            let value : Int?
            
            switch signal_label
            {
                case .HR:
                    value = HR
                    
                case .RR_interval:
                    // FIXME: add the index to the function parameter
                    value = (RR_interval.count > 0) ? RR_interval[0] : nil
                    
                default:
                    value = nil
            }
            
            return value
        }
        
    }
    
    
    /**
     * The configuration bit set for the First byte in the HRS data stream
     */
    struct Status: OptionSet
    {
        
        static let HR_16_bit    = Status(rawValue: 0b00000001)
        static let RR_interval  = Status(rawValue: 0b00010000)
        
        let rawValue: UInt8

    }
    
    
    // MARK: - Public interface
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_csv_header() -> String
    {
        
        let hr_label     = BLE_signal_type.HR.short_name
        let rr_int_label = BLE_signal_type.RR_interval.short_name
        
        let rr_intervals = Array(
                repeating: rr_int_label,
                count    : Self.max_number_of_rr_intervals
            )
            .joined(separator: ",")
        
        return "Timestamp,\(hr_label),\(rr_intervals)\n"
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_info_description() -> String
    {
        
        let signals_description = get_description_for_signals(
                [.HR, .RR_interval]
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
                timestamp   : 0,
                HR          : 0,
                RR_interval : []
            )
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func get_minimum_numerics() -> [BLE_signal]
    {
        
        var signal_list : [BLE_signal] = []
        
        if let signal = get_signal( .HR )
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
            case .HR:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "bpm",
                    gain      : 1,
                    frequency : 1,
                    value     : 0
                )
                
            case .RR_interval:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "ms",
                    gain      : (1000.0 / 1024.0),
                    frequency : 1,
                    value     : 0
                )
                
            default:
                signal = nil
        }
        
        return signal
        
    }
    
    
    // MARK: - Private interface

    
    /**
     * The maximum number of RR intervals defined by the HRS specification
     */
    private static let max_number_of_rr_intervals : Int = 9
    
}
