/**
 * \file    ble_nppg_spec_decoder.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 3, 2022
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
 *   "EC0A883A-4D24-11E7-B114-B2F933D5FE66":  "Nonin PPG"
 *
 * Version "113142-000-02" Rev B as published by Nonin
 *
 * Nonin uses Big-endian format to transmit data
 */
final class BLE_NPPG_spec_decoder : BLE_decoder
{
    
    // MARK: - Characteristic identifiers
    
    
    /**
     * See ``BLE_decoder`` protocol for documentation
     */
    private(set) var id    : CBCharacteristic.ID_type    =
        .init(string: "EC0A883A-4D24-11E7-B114-B2F933D5FE66")
    
    /**
     * See ``BLE_decoder`` protocol for documentation
     */
    private(set) var label : CBCharacteristic.Label_type = .nonin_PPG
    
    
    init()
    {
        /**
         * Every data frame sent by Nonin should have this number of bytes:
         *
         * PPG samples + length byte + 2-byte counter
         */
        minimum_packet_length = (number_of_PPG_samples * 2) + 1 + 2
    }
    
    // MARK: - Decoding raw BLE data
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func decode(
            _ ble_data : ASB_data
        ) throws -> BLE_spec_Output?
    {
        
        if ble_data.data.isEmpty
        {
            return nil
        }
        
        let length = Int( ble_data.data[0] )

        if length != ble_data.data.count
        {
            throw ASB_error.decode_data(
                    description: "Frame size is in the wrong format"
                )
        }
        
        if ble_data.data.count < minimum_packet_length
        {
            throw ASB_error.decode_data(
                    description: "Frame too small: only " +
                                 "\(ble_data.data.count) bytes received"
                )
        }

        let data = ble_data.data
        
        var samples = [Int](repeating: 0, count: number_of_PPG_samples)
        var j = 0
        
        // Loop excluding the last 2 bytes
        for i in stride(from: 1, to: data.count - 2, by: 2)
        {
            samples[j] = (Int(data[i]) << 8) + Int(data[i+1])
            j += 1
        }
        
        let counter = (Int( data[data.count - 2] ) << 8) +
                      Int( data[data.count - 1] )
        
        return Output(
                timestamp : ble_data.timestamp,
                counter   : counter,
                PPG       : samples
            )
    }
    
    
    // MARK: - BLE spec definitions
    
    
    /**
     * The data type that the `BLE` decodes
     */
    struct Output : BLE_spec_Output
    {
        
        let timestamp : ASB_timestamp
        let counter   : Int
        let PPG       : [Int]
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         *
         *
         * Returns: One row per PPG sample, repeating timestamp and counter
         *         for every PPG sample
         */
        @inline(__always)
        func csv_value() -> String
        {
            let fixed_columns = "\(timestamp),\(counter),"
            
            let ppg_values = PPG.enumerated()
                .map { "\(fixed_columns)\($0),\($1)" }
                .joined(separator: "\n")
            
            return "\(ppg_values)\n"
            
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
                case .counter:
                    value = counter
                    
                case .PPG:
                    value = (PPG.count > 0) ? PPG[0] : nil
                    
                default:
                    value = nil
            }
            
            return value
            
        }
        
    }
    
    
    // MARK: - Public interface
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_csv_header() -> String
    {
        
        let counter_label = BLE_signal_type.counter.short_name
        let ppg_label     = BLE_signal_type.PPG.short_name
        
        
        return "Timestamp,\(counter_label),Packet_sequence,\(ppg_label)\n"
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_info_description() -> String
    {
        
        let counter_description = get_description_for_signals( [.counter] )
        let ppg_description     = get_description_for_signals( [.PPG] )
        
        let info : String =
            """
            \(output_info_description_heder)
            Timestamp , "Unix epoch" , nanoseconds , ,
            \(counter_description)
            Packet_sequence , "0-24 packet sequence counter" , numeric , ,
            \(ppg_description)
            """
        
        return info
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_empty_value() -> BLE_spec_Output
    {
        
        return Output(
                timestamp : 0,
                counter   : 0,
                PPG       : []
            )
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func get_minimum_numerics() -> [BLE_signal]
    {
        
        var signal_list : [BLE_signal] = []
        
        if let signal = get_signal( .counter )
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
            case .counter:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "uint16",
                    gain      : 1,
                    frequency : 3,
                    value     : 0
                )
            case .PPG:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "a.d.u.",
                    gain      : 1,
                    frequency : 75,
                    value     : 0
                )
                
            default:
                signal = nil
        }
        
        return signal
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * Nonin should send 25 PPG samples per data frame
     */
    private let number_of_PPG_samples : Int = 25
    
    /**
     * Every data frame sent by Nonin should have this number of bytes:
     *
     * PPG samples + length byte + 2-byte counter
     */
    private let minimum_packet_length : Int
    
    
}
