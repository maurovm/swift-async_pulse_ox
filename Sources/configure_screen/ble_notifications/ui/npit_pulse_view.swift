/**
 * \file    npit_pulse_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 15, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import AVFoundation

/**
 * Show the values of a NPIT_pulse from the "Nonin Pulse Interval Time"
 * BLE characteristic
 */
struct NPIT_pulse_view: View
{
    let id                  : UUID
    let bad_pulse_flag      : Bool
    let PAI                 : BLE_signal
    let pulse_time          : BLE_signal
    let show_physical_units : Bool
    
    var body: some View
    {
        
        GeometryReader
        {
            geo in
            
            HStack
            {
                Option_set_flag_view(
                        name: "Bad pulse",
                        is_on: bad_pulse_flag
                    )
                    .frame(width: geo.size.width * 0.2, height: geo.size.height)
                    
                BLE_signal_view(
                        id       : PAI.id,
                        name     : PAI.name,
                        units    : PAI.units,
                        gain     : PAI.gain,
                        value    : PAI.value,
                        show_physical_units : show_physical_units
                    )
                
                BLE_signal_view(
                        id       : pulse_time.id,
                        name     : pulse_time.name,
                        units    : pulse_time.units,
                        gain     : pulse_time.gain,
                        value    : pulse_time.value,
                        show_physical_units : show_physical_units
                    )
            }
        }
        .border(.gray.opacity(0.6), width: 2)
        .cornerRadius(10)
        
    }
    
}


struct NPIT_pulse_view_Previews: PreviewProvider
{
    
    /**
      * Dummy data to be able to generate the Preview
      */
    class dummy_model: ObservableObject
    {
         
         let pai_signal   : BLE_signal
         let pulse_signal : BLE_signal
         
         init()
         {
             
             let decoder = BLE_NPIT_spec_decoder()
             
             if let signal = decoder.get_signal(.PAI)
             {
                 pai_signal = signal
             }
             else
             {
                 pai_signal = BLE_signal(
                        type      : .PAI,
                        units     : "unknown",
                        gain      : 0,
                        frequency : 1,
                        value     : 0
                     )
             }
             
             if let signal = decoder.get_signal(.pulse_time)
             {
                 pulse_signal = signal
             }
             else
             {
                 pulse_signal = BLE_signal(
                        type      : .pulse_time,
                        units     : "unknown",
                        gain      : 0,
                        frequency : 1,
                        value     : 0
                     )
             }
             
         }
    }
    
    
    static var previews: some View
    {
        
        VStack
        {
            NPIT_pulse_view(
                    id                  : UUID(),
                    bad_pulse_flag      : true,
                    PAI                 : dummy_model().pai_signal,
                    pulse_time          : dummy_model().pulse_signal,
                    show_physical_units : true
                )
                .padding()
        }
        .previewLayout(.fixed(width: 200, height: 120))
        
    }
}
