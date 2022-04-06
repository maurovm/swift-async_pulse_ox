/**
 * \file    ble_decoder.swift
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
import AsyncBluetooth
import SensorRecordingUtils
import CoreBluetooth


protocol BLE_decoder
{
        
    // MARK: - Characteristic identifiers
    
    
    /**
     * The unique id of the characteristic this decode process data for
     */
    var id    : CBCharacteristic.ID_type    { get }
    
    /**
     * The unique label of the characteristic this decode process data for
     */
    var label : CBCharacteristic.Label_type { get }
        
    
    // MARK: - Decoding raw BLE data
    
    
    /**
     * Decodes the raw data sent by the BLE device
     */
    func decode(
            _ ble_data : ASB_data
        ) throws -> BLE_spec_Output?
    
    
    // MARK: - Public interface
    
    
    /**
     * The Header for a CSV text file
     *
     * Returns: A one row string, with a carriage return '\n' character
     *          at the end. It contains the raw names for each csv data column
     */
    func output_csv_header() -> String
    
    
    /**
     * A description textual description of this class' Output structure.
     * It contains one line per data item/field
     *
     * It is often used to write a ble_XXX_decoder-info.txt file, companion
     * to the data csv file
     */
    func output_info_description() -> String
    
    /**
     * The header for the `output_info_description` functions.
     *
     * Note that the returning string does not end with the carriage return
     * character
     */
    var output_info_description_heder : String {get}
    
    
    /**
     * Empty value for the Output struct for the decoder. It is typically
     * used to initialised memory buffers
     */
    func output_empty_value() -> BLE_spec_Output
    
    
    /**
     * Return the minimum set of vital sign numerics. This is typically used
     * to display in the UI a minimum set of signals for this decoder
     */
    func get_minimum_numerics() -> [BLE_signal]
    
    
    /**
     * Return the signal structure for a given signal type decoded by this
     * characteristic.
     *
     * The signal contains the information to transform the raw data
     * recorded to physical units. Refer to the offcial Nonin documentation
     *  for more information about the "gain" factor
     *
     * Returns: The signal for the requested signal type, nil if this
     *          decoder does not support the requested signal type
     */
    func get_signal(
            _ signal_type : BLE_signal_type
        ) -> BLE_signal?
    
    
    /**
     * Returns a multi-line string (each line separated by the carriage return
     * character "\n" ) with the description the requested signals, one line
     * per signal.
     *
     * This is often used by the function `output_info_description()`
     */
    func get_description_for_signals(
            _  signals : [BLE_signal_type]
        ) -> String
    
    
    /**
     * Returns a one-line string (separated by the character "," ) with the
     * short name the requested signals.
     *
     * This is often used by the function `output_csv_header()` to write
     * the CSV headers
     */
    func get_name_for_signals(
            _  signals : [BLE_signal_type]
        ) -> String
    
}


extension BLE_decoder
{
    
    var output_info_description_heder : String
    {
        "name , description, units, gain, frequency"
    }
    
    
    func get_description_for_signals(
            _  signals : [BLE_signal_type]
        ) -> String
    {
        
        return signals
            .map
            {
                signal_type in
                
                if let signal = get_signal(signal_type)
                {
                    return signal.csv_description
                }
                else
                {
                    // a description with no units, gain or frequency
                    
                    return "\(signal_type.short_name) , " +
                           "\"\(signal_type.long_name)\" , , , "
                }
                
            }
            .joined(separator: "\n")
        
    }
    
    
    func get_name_for_signals(
            _  signals : [BLE_signal_type]
        ) -> String
    {
        
        return signals
            .map { $0.short_name }
            .joined(separator: ",")
        
    }
    
}
