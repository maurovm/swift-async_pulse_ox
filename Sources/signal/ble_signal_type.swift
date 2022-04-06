/**
 * \file    ble_signal_type.swift
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


/**
 * The type of signals this spec reads from raw BLE data
 */
enum BLE_signal_type
{
    
    case battery_voltage
    case battery_percentage
    case PAI
    case pulse_time
    case counter
    case SpO2
    case HR
    case RR_interval
    case PPG
    
    
    var short_name : String
    {
        switch self
        {
            case .battery_voltage:
                return "Batt volt"
                
            case .battery_percentage:
                return "Bat perc"
                
            case .PAI:
                return "PAI"
                
            case .pulse_time:
                return "Pulse time"
                
            case .counter:
                return "Counter"
                
            case .SpO2:
                return "SpO2"
                
            case .HR:
                return "HR"
                
            case .RR_interval:
                return "RR int"
                
            case .PPG:
                return "PPG"
        }
    }
    
    
    var long_name : String
    {
        switch self
        {
            case .battery_voltage:
                return "Battery Voltage"
                
            case .battery_percentage:
                return "Battery Percentage"
                
            case .PAI:
                return "Pulse Amplitude Index"
                
            case .pulse_time:
                return "Pulse time"
                
            case .counter:
                return "Frame sequence counter"
                
            case .SpO2:
                return "Peripheral Oxygen Saturation"
                
            case .HR:
                return "Heart Rate"
                
            case .RR_interval:
                return "RR interval"
                
            case .PPG:
                return "Photoplethysmogram"
        }
    }
    
}
