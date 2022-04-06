/**
 * \file    ble_npit_spec_decoder.swift
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
 * "34E27863-76FF-4F8E-96F1-9E3993AA6199" : "Nonin Pulse Interval Time"
 *
 * Version "113142-000-02" Rev B as published by Nonin
 *
 * Nonin uses Big-endian format to transmit data
 */
final class BLE_NPIT_spec_decoder : BLE_decoder
{
    
    // MARK: - Characteristic identifiers
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    private(set) var id    : CBCharacteristic.ID_type    =
        .init(string: "34E27863-76FF-4F8E-96F1-9E3993AA6199")
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    private(set) var label : CBCharacteristic.Label_type =
        .nonin_pulse_interval_time
    
    
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
        
        
        // Pulses start on byte 4 onwards, and each is 4 bytes in size
        let number_of_pulses = (length - minimum_packet_length) / pulse_byte_length
        
        if number_of_pulses > Self.max_number_of_pulses
        {
            throw ASB_error.decode_data(
                description: "\(number_of_pulses) pulses recived, the " +
                             "maximum allowed is \(Self.max_number_of_pulses)"
                )
        }
        
        var samples = [NPIT_Pulse](
                repeating: .init(bad_pulse_flag: true, PAI: 0, pulse_time: 0),
                count: number_of_pulses
            )
        
        var data_index = minimum_packet_length
        
        for pulse_index in 0..<number_of_pulses
        {
            let mso = (data[data_index] & PAI_MSO_mask)
            let lso = data[data_index + 1]
            
            let pulse = NPIT_Pulse(
                bad_pulse_flag: (data[data_index] & bad_pulse_flag_mask) > 0,
                PAI           : (Int(mso) << 8) + Int(lso),
                pulse_time    : (Int( data[data_index+2] ) << 8) +
                                Int( data[data_index+3] )
            )
            
            samples[pulse_index] = pulse
            
            data_index += pulse_byte_length
        }
        
        return Output(
                timestamp : ble_data.timestamp,
                counter   : (Int( data[1] ) << 8) + Int( data[2] ),
                status    : Status(rawValue: data[3]),
                pulses    : samples
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
        let status    : Status
        let pulses    : [NPIT_Pulse]
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         */
        @inline(__always)
        func csv_value() -> String
        {
            
            let status_values = Status.all_options
                .map { status.contains($0) ? "1" : "0" }
                .joined(separator: ",")
            
            // Convert the values for all NPIT pulses into a single string
            
            let npit_values = pulses
                .map
                {
                    "\($0.bad_pulse_flag ? "1" : "0"),\($0.PAI),\($0.pulse_time)"
                }
                .joined(separator: ",")
            
            
            // Append extra "," if needed to fill the empty columns
            
            let current_pulse_columns = pulses.count * Self.columns_per_pulse
            
            let num_of_empty_columns =
                Self.total_num_of_pulse_columns - current_pulse_columns
            
            let extra_csv_separators : String
            
            if num_of_empty_columns > 0
            {
                extra_csv_separators = String(
                        repeating: ",", count: num_of_empty_columns
                    )
            }
            else
            {
                extra_csv_separators = ""
            }
            
            
            return "\(timestamp),\(counter),\(status.rawValue)," +
                "\(status_values),\(npit_values),\(extra_csv_separators)\n"
            
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
                    
                case .PAI:
                    // FIXME: add the index to the function parameter
                    value = (pulses.count > 0) ? pulses[0].PAI : nil
                    
                case .pulse_time:
                    // FIXME: add the index to the function parameter
                    value = (pulses.count > 0) ? pulses[0].pulse_time : nil
                    
                default:
                    value = nil
            }
            
            return value
        }
        
        
        // Private state
        
        
        private static let columns_per_pulse = 3
        private static let total_num_of_pulse_columns =
            BLE_NPIT_spec_decoder.max_number_of_pulses * columns_per_pulse
        
    }
    
    
    /**
     * The status byte field (Byte 2)
     */
    struct Status: OptionSet
    {
        
        static let not_set          = Status([])    // 0b00000000
        static let invalid_signal   = Status(rawValue: 0b00000001)
        static let pulse_rate_high  = Status(rawValue: 0b00000010)
        
        static let all_options : [Status] = [
                .invalid_signal,
                .pulse_rate_high
            ]
        
        let rawValue: UInt8
        
    }
    
    
    /**
     * A pulse in Nonin Data Format 20
     */
    struct NPIT_Pulse
    {
        
        let bad_pulse_flag : Bool
        let PAI            : Int
        let pulse_time     : Int
        
    }
    
    
    // MARK: - Public interface
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_csv_header() -> String
    {
        
        let counter_label     = BLE_signal_type.counter.short_name
        
        let status_labels = "Invalid_signal,Pulse_rate_high"
        
        let npit_signals_label = get_name_for_signals(
                [ .PAI, .pulse_time ]
            )
        
        let npit_label = "Bad_pulse,\(npit_signals_label)"
        
        let all_npit_pulses_label = Array(
                repeating: npit_label,
                count    : Self.max_number_of_pulses
            )
            .joined(separator: ",")
        
        return "Timestamp,\(counter_label),Status,\(status_labels)," +
            "\(all_npit_pulses_label)\n"
    
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_info_description() -> String
    {
        
        let counter_description = get_description_for_signals( [.counter] )
        
        let status_info : String =
            """
            Invalid_signal  , "Invalid signal flag"                  , boolean , ,
            Pulse_rate_high , "Pulse Rate too high for this feature" , boolean , ,
            """
        
        let npit_signals_description = get_description_for_signals(
                [ .PAI, .pulse_time ]
            )
        
        let info : String =
            """
            \(output_info_description_heder)
            Timestamp , "Unix epoch" , nanoseconds , ,
            \(counter_description)
            Status , "Signal status" , bitset , ,
            \(status_info)
            Bad_pulse  , "The given pulse has poor signal quality" , boolean , ,
            \(npit_signals_description)
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
            status    : .not_set,
            pulses    : []
        )
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func get_minimum_numerics() -> [BLE_signal]
    {
        
        let labels: [BLE_signal_type] = [ .PAI , .pulse_time ]
        
        return labels.compactMap { get_signal($0) }
        
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
                    frequency : 1,
                    value     : 0
                )
                
            case .PAI:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "%",
                    gain      : 0.01,
                    frequency : 1,
                    value     : 0
                )
                
            case .pulse_time:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "ms",
                    gain      : 0.1,
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
    private let minimum_packet_length : Int = 4
    
    /**
     * Each NPIT_pulse is of 4 bytes in length
     */
    private let pulse_byte_length     : Int = 4
    
    /**
     * Bit flag when the pulse is of bad quality
     */
    private let bad_pulse_flag_mask : UInt8 = 0b01000000
    
    /**
     * Bits that correspond to the Most Significant Octect (MSO)
     * for the PAI value
     */
    private let PAI_MSO_mask : UInt8 = 0b00001111
    
    
    /**
     * According to the protocol, there are a maximum of 6 pulses
     * per data packet received
     */
    private static let max_number_of_pulses : Int = 6
    
}
