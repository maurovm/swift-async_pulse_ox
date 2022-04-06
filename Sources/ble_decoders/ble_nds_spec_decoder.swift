/**
 * \file    ble_nds_spec_decoder.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 7, 2022
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
 *   "EC0A9302-4D24-11E7-B114-B2F933D5FE66":
 *            "Nonin Device Status"
 *
 * Version "113142-000-02" Rev B as published by Nonin
 *
 * Nonin uses Big-endian format to transmit data
 */
final class BLE_NDS_spec_decoder : BLE_decoder
{
    
    // MARK: - Characteristic identifiers
    
    
    /**
     * See ``BLE_decoder`` protocol for documentation
     */
    private(set) var id    : CBCharacteristic.ID_type    =
        .init(string: "EC0A9302-4D24-11E7-B114-B2F933D5FE66")
    
    /**
     * See ``BLE_decoder`` protocol for documentation
     */
    private(set) var label : CBCharacteristic.Label_type = .nonin_device_status

    
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
            timestamp          : ble_data.timestamp,
            counter            : (Int( data[5] ) << 8) + Int( data[6] ),
            battery_voltage    : Int( data[3] ),
            battery_percentage : Int( data[4] ),
            sensor             : Sensor_type(rawValue: data[1]),
            error              : Device_Error(rawValue: data[2])
        )
    }
    
    
    // MARK: - BLE spec definitions
    
    
    /**
     * The data that the `BLE` decodes
     */
    struct Output : BLE_spec_Output
    {
        
        let timestamp          : ASB_timestamp
        let counter            : Int
        let battery_voltage    : Int
        let battery_percentage : Int
        let sensor             : Sensor_type
        let error              : Device_Error
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         */
        @inline(__always)
        func csv_value() -> String
        {
            
            let sensor_type_values =
                    sensor.contains(.pulse_oximeter) ? "1" : "0"
            
            let device_error_values = Device_Error.all_options
                .map { error.contains($0) ? "1" : "0" }
                .joined(separator: ",")
            
            
            return "\(timestamp),\(counter),\(battery_voltage)," +
                   "\(battery_percentage)," +
                   "\(sensor.rawValue),\(sensor_type_values)," +
                   "\(error.rawValue),\(device_error_values)\n"
            
        }
        
        
        /**
         * See ``BLE_spec_Output`` protcol for documentation
         */
        @inline(__always)
        func value(_ signal_label : BLE_signal_type) -> Int?
        {
            let value : Int?
            
            switch signal_label
            {
                case .battery_voltage:
                    value = battery_voltage
                    
                case .battery_percentage:
                    value = battery_percentage
                    
                case .counter:
                    value = counter
                    
                default:
                    value = nil
            }
            
            return value
        }
        
    }
    
    
    /**
     * Flag that defines the type of sensor connected
     */
    struct Sensor_type: OptionSet
    {
        static let not_set        = Sensor_type([])    // 0b00000000
        static let pulse_oximeter = Sensor_type(rawValue: 0b00000001)
        
        let rawValue: UInt8
        
    }
    
    
    /**
     * Flag that indicates if there is an error with the device
     */
    struct Device_Error: OptionSet
    {
        static let no_error            = Device_Error([])    // 0b00000000
        static let no_sensor_connected = Device_Error(rawValue: 0b00000001)
        static let sensor_fault        = Device_Error(rawValue: 0b00000101)
        static let system_error        = Device_Error(rawValue: 0b00000110)
        
        static let all_options : [Device_Error] = [
                .no_error,
                .no_sensor_connected,
                .sensor_fault,
                .system_error
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
                [ .counter, .battery_voltage, .battery_percentage]
            )
        
        let sensor_type_labels  = "Pulse_oximeter"
        
        let device_error_labels =
                "No_error,No_sensor_connected,Sensor_fault,System_error"
        
        return "Timestamp,\(signals_label),Sensor_type,\(sensor_type_labels)," +
               "Device_error,\(device_error_labels)\n"
        
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func output_info_description() -> String
    {
        let signals_description = get_description_for_signals(
                [ .counter, .battery_voltage, .battery_percentage]
            )
        
        
        let sensor_type_info : String =
            """
            Pulse_oximeter , "Pulse Oximeter Sensor is attached" , boolean , ,
            """
        
        let device_error_info : String =
            """
            No_error            , "No errors reported by the device"        , boolean , ,
            No_sensor_connected , "No sensor is connected to the device"    , boolean , ,
            Sensor_fault        , "A fault in the sensor has been detected" , boolean , ,
            System_error        , "An error internally occurred"            , boolean , ,
            """
        
        
        let info : String =
            """
            \(output_info_description_heder)
            Timestamp , "Unix epoch" , nanoseconds , ,
            \(signals_description)
            Sensor_type , "" , bitset , ,
            \(sensor_type_info)
            Device_error , "" , bitset , ,
            \(device_error_info)
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
            counter            : 0,
            battery_voltage    : 0,
            battery_percentage : 0,
            sensor             : .not_set,
            error              : .no_error
        )
    }
    
    
    /**
     * See ``BLE_decoder`` protcol for documentation
     */
    func get_minimum_numerics() -> [BLE_signal]
    {
        
        let labels : [BLE_signal_type] =
            [ .battery_voltage , .battery_percentage ]
        
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
                
            case .battery_percentage:
                signal = BLE_signal(
                    type      : signal_type,
                    units     : "%",
                    gain      : 1,
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
                
            default:
                signal = nil
        }
        
        return signal
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * Every data frame sent by Nonin should have this number of bytes
     */
    private let minimum_packet_length : Int = 7
}
