/**
 * \file    ble_signal.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 8, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI


/**
 * The value recorded by a device. Usually either an 8-bit or 16-bit
 * value. For example, a 16-bit raw ECG analog units. To compute the value in
 * physical units, for example mV, compute:
 *
 *     ECG in mV = value * gain
 */
struct BLE_signal : Identifiable
{
    
    let id          : UUID  = UUID()
    let type        : BLE_signal_type
    let units       : String
    let gain        : Float
    let frequency   : Int
    var value       : Int
    
    
    var name : String
    {
        type.short_name
    }
    
    
    var long_name : String
    {
        type.long_name
    }
    
    
    /**
     * Returns: a description of the signal for csv files, in the format:
     *
     *    name , description, units, gain, frequency
     */
    var csv_description : String
    {
        return "\(name) , \"\(long_name)\" , \(units) , \(gain) , \(frequency)"
    }
    
}
