/**
 * \file    vital_sign_numerics_model.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 1, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import CoreBluetooth
import AsyncBluetooth



@MainActor
final class Vital_sign_numerics_model : ObservableObject
{
    
    @Published var vital_signs : [BLE_signal] = []
    
    @Published var battery_percentage : Int?
    
    
    init(
            _  signal_to_display  : [BLE_signal] = [],
               battery_percentage : Int?         = nil
        )
    {
        
        if signal_to_display.isEmpty == false
        {
            add_vital_signs(signal_to_display)
        }
        
        self.battery_percentage = battery_percentage
        
    }
    
    
    // MARK: - Add signal definitions
    
    
    func remove_all_signals()
    {
        
        vital_signs.removeAll()
        battery_percentage = nil
        
    }
    
    
    func add_vital_signs( _  signals_to_display : [BLE_signal] )
    {
        
        vital_signs.append(contentsOf: signals_to_display)
        
    }
    
    
    // MARK:  - New values to display
    
    
    func new_signal_value( _ output : BLE_spec_Output )
    {
        
        for index in  0..<vital_signs.count
        {
            if let value = output.value( vital_signs[index].type )
            {
                vital_signs[index].value = value
            }
        }
        
    }
    
    
    func new_battery_percentage( _ output : BLE_spec_Output )
    {
        
        if let value = output.value( .battery_percentage )
        {
            battery_percentage = value
        }
        
    }
    
}
