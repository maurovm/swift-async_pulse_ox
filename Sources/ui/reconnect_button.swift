/**
 * \file    reconnect_button.swift
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
import SensorRecordingUtils


struct Reconnect_button: View
{
    
    var body: some View
    {
        
        ZStack(alignment: .center)
        {
            
            Bordered_rounded_rectangle(
                    cornerRadius: radius,
                    style:        .continuous,
                    fill_color:   .white,
                    stroke_color: .black,
                    stroke_width: 1.0
                )
            
            VStack(alignment: .center)
            {
                Image(systemName: "arrow.clockwise")
                    .font(.system(.caption2))
                    .foregroundColor(.black)
                
                Text("Connect")
                    .font(.system(size: 10))
            }
            
        }
        
    }
    
    
    // MARK: - Private state
    
    
    private let radius = 10.0
    
}
