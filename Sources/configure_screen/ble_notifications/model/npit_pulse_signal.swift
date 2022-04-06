/**
 * \file    npit_pulse_signal.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 15, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation

/**
 * A pulse from the Nonin Pulse Interval Time (NPIT) characteristic
 */
struct NPIT_pulse_signal : Identifiable
{
    
    let id             : UUID  = UUID()
    var bad_pulse_flag : Bool
    var PAI            : BLE_signal
    var pulse_time     : BLE_signal
    
}
