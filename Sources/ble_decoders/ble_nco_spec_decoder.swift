/**
 * \file    ble_nco_spec_decoder.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 5, 2022
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
 *   "0AAD7EA0-0D60-11E2-8E3C-0002A5D5C51B":
 *            "Nonin Continuous Oximetery Characteristic"
 *
 * Version "113142-000-02" Rev B as published by Nonin
 *
 * Nonin uses Big-endian format to transmit data
 */
final class BLE_NCO_spec_decoder : BLE_decoder
{
    
    // MARK: - Characteristic identifiers
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    private(set) var id    : CBCharacteristic.ID_type    =
        .init(string: "0AAD7EA0-0D60-11E2-8E3C-0002A5D5C51B")
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    private(set) var label : CBCharacteristic.Label_type =
        .nonin_continuous_oximetry

    
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
        
        return Output(
            timestamp       : ble_data.timestamp,
            status          : Status(rawValue: data[1]),
            battery_voltage : Int( data[2] ),
            PAI             : (Int( data[3] ) << 8) + Int( data[4] ),
            counter         : (Int( data[5] ) << 8) + Int( data[6] ),
            SpO2            : Int( data[7]) ,
            HR              : (Int( data[8] ) << 8) + Int( data[9] )
        )
        
    }
    
    
    // MARK: - BLE spec definitions
    
    
    /**
     * The data type that the `BLE` decodes
     */
    struct Output : BLE_spec_Output
    {
        
        let timestamp       : ASB_timestamp
        let status          : Status
        let battery_voltage : Int
        let PAI             : Int
        let counter         : Int
        let SpO2            : Int
        let HR              : Int
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         */
        @inline(__always)
        func csv_value() -> String
        {
            
            let status_values = Status.all_options
                .map { status.contains($0) ? "1" : "0" }
                .joined(separator: ",")
            
            return "\(timestamp),\(counter),\(battery_voltage),\(PAI)," +
                   "\(SpO2),\(HR),\(status.rawValue),\(status_values)\n"
            
        }
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         */
        func value(_ signal_label : BLE_signal_type) -> Int?
        {
            let value : Int?
            
            switch signal_label
            {
                case .battery_voltage:
                    value = battery_voltage
                    
                case .PAI:
                    value = PAI
                    
                case .counter:
                    value = counter
                    
                case .SpO2:
                    value = SpO2
                    
                case .HR:
                    value = HR
                    
                default:
                    value = nil
            }
            
            return value
        }
        
    }
    
    
    /**
     * The status byte field (Byte 2)
     */
    struct Status: OptionSet
    {
        
        static let not_set          = Status([])    // 0b00000000
        static let weak_signal      = Status(rawValue: 0b00000010)
        static let smart_point      = Status(rawValue: 0b00000100)
        static let searching        = Status(rawValue: 0b00001000)
        static let sensor_connected = Status(rawValue: 0b00010000)
        static let low_battery      = Status(rawValue: 0b00100000)
        static let encrypted        = Status(rawValue: 0b01000000)
        
        static let all_options : [Status] = [
                .weak_signal,
                .smart_point,
                .searching,
                .sensor_connected,
                .low_battery,
                .encrypted
            ]
        
        let rawValue: UInt8
        
    }
    
    
    // MARK: - Public interface
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_csv_header() -> String
    {
        let signals_label = get_name_for_signals(
                [ .counter, .battery_voltage, .PAI, .SpO2, .HR ]
            )
        
        let status_labels =
            "Weak_signal,Smart_point,Searching_for_pulse," +
            "Sensor_connected,low_battery,encrypted"
        
        return "Timestamp,\(signals_label),Status,\(status_labels)\n"
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_info_description() -> String
    {
        
        let signals_description = get_description_for_signals(
                [.counter, .battery_voltage, .PAI, .SpO2, .HR]
            )
        
        let status_info : String =
            """
            Weak_signal         , "Pulse signal strength is 0.3% modulation or less" , boolean , ,
            Smart_point         , "Data passed the SmartPoint Algorithm"             , boolean , ,
            Searching_for_pulse , "Searching for consecutive pulse signals"          , boolean , ,
            Sensor_connected    , "1 -> Sensor is correctly fitted on finger"        , boolean , ,
            low_battery         , "Batteries are low"                                , boolean , ,
            encrypted           , "1 -> connection is encrypted"                     , boolean , ,
            """

        
        let info : String =
            """
            \(output_info_description_heder)
            Timestamp , "Unix epoch" , nanoseconds , ,
            \(signals_description)
            Status , "device status" , bitset , ,
            \(status_info)
            """
        
        return info
        
    }
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_empty_value() -> BLE_spec_Output
    {
        
        return Output(
                timestamp       : 0,
                status          : .not_set,
                battery_voltage : 0,
                PAI             : 0,
                counter         : 0,
                SpO2            : 0,
                HR              : 0
            )
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func get_minimum_numerics() -> [BLE_signal]
    {
     
        let labels : [BLE_signal_type] = [ .HR , .SpO2 , .PAI ]
        
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
            case .battery_voltage:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "V",
                    gain      : 0.1,
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
                
            case .counter:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "uint16",
                    gain      : 1,
                    frequency : 1,
                    value     : 0
                )
                
            case .SpO2:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "%",
                    gain      : 1,
                    frequency : 1,
                    value     : 0
                )
                
            case .HR:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "bpm",
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
     * Every data frame sent by Nonin should have this minimum number of bytes
     */
    private let minimum_packet_length : Int = 10
    
}
