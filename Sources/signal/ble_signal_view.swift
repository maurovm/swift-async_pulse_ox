/**
 * \file    ble_signal_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 7, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import AVFoundation
import SensorRecordingUtils


/**
 * Show the value of a Signal value as either , the raw values recorded
 * by a device, or in physical units (such as beats per minute for heart rate).
 *
 * The physical units are rounded to the
 */
struct BLE_signal_view: View
{

    let id    : UUID
    let name  : String
    let units : String
    let gain  : Float
    var value : Int
    
    
    /**
     * Flag so the View shows the value in physical units (such as
     * beats per minute, floating point battery voltaga, etc), or
     * as the original raw Integers capture by a device
     */
    var show_physical_units : Bool = true
    
    
    
    var body: some View
    {
        
        GeometryReader
        {
            geo in
            
            VStack(alignment: .center, spacing: 0)
            {
                Signal_header_view
                    //.frame(height: geo.size.height * 0.5)
                
                Signal_value_view
            }
        }
        
    }
    
    
    // MARK: - Private views
    
    
    private var Signal_header_view : some View
    {
        
        ZStack
        {
            Color.black.corner_radius(
                    radius :  panel_radius,
                    corners: [.topLeft, .topRight]
                )
                .shadow(color: .gray, radius: 5, x: 2, y: 2)
            
            VStack
            {
                Text(name)
                    .font(title_font).foregroundColor(.yellow)
                
                if show_physical_units  &&  units.isEmpty == false
                {
                    Text("(" + units + ")")
                        .font(subtitle_font).foregroundColor(.yellow)
                }
            }
        }
        
    }
    
    
    private var Signal_value_view : some View
    {
        
        ZStack
        {
            Color.white.corner_radius(
                    radius :  panel_radius,
                    corners: [.bottomLeft, .bottomRight]
                )
                .shadow(color: .gray, radius: 5, x: 2, y: 2)
            
            Text(signal_value).font(value_font).foregroundColor(.black)
        }
        
    }
    
    
    // MARK: - Private state
    
    
    // Tenths of a value
    private let decimal_precision : Float = 10
    
    private let panel_radius : CGFloat = 10.0
    
    
    private let title_font: Font = .system(
            size: 13, weight: .regular, design: .default
        )
    
    private let subtitle_font: Font = .system(
            size: 11, weight: .regular, design: .default
        )
    
    private let value_font: Font = .system(
            size: 18, weight: .regular, design: .default
        )
    
    
    private var signal_value : String
    {
        
        let string_value : String
        
        if show_physical_units && (gain != 1)
        {
            let rounded_value = round(Float(value) * gain * decimal_precision) /
                    decimal_precision
            
            string_value = String(rounded_value)
        }
        else
        {
            string_value = String(value)
        }
        
        return string_value
        
    }
    
}



struct Signal_view_Previews: PreviewProvider
{
    
    static var previews: some View
    {
        
        VStack(spacing: 20)
        {
            Group
            {
                BLE_signal_view(
                    id        : UUID(),
                    name      : "HR",
                    units     :  "bpm",
                    gain      : 1,
                    value     : 68
                )
            
                BLE_signal_view(
                    id        : UUID(),
                    name      : "Bat volt",
                    units     :  "V",
                    gain      : 0.1,
                    value     : 33
                )
            }
            .frame(width: 70, height: 70)
        }
        .padding()
        .background(.cyan)
        .previewLayout(.fixed(width: 120, height: 260))
        
    }
    
}
