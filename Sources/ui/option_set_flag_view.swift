/**
 * \file    option_set_flag_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 14, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI


/**
 * Display an option flag for a given OptionSet
 */
struct Option_set_flag_view: View
{
    
    var name  : String  = "Status"
    var is_on : Bool    = false
    
    
    var body: some View
    {
        
        GeometryReader
        {
            geo in
            
            VStack(spacing: 0)
            {
                Divider()
                
                Text(name)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 10, weight: .bold, design: .default))
                    .frame(
                            width    : geo.size.width,
                            height   : geo.size.height * 0.6,
                            alignment: .center
                        )
                
                Divider()
                
                Toggle("", isOn: .constant(is_on))
                    .toggleStyle(CheckToggleStyle())
                    .frame(
                        width    : geo.size.width * 0.3,
                            alignment: .center
                        )
            }
            .frame(height : geo.size.height)
        }
        
    }
    
}


fileprivate struct CheckToggleStyle: ToggleStyle
{
    
    func makeBody(configuration: Configuration) -> some View
    {
        
        Circle()
            .fill( configuration.isOn ? .green : .gray)
            .brightness(configuration.isOn ? 0 : 0.3)
            .padding(0)
            .overlay(
                Circle()
                    .stroke(.orange, lineWidth: 1)
                    .shadow(radius: 2)
            )
        
    }
    
}



struct Option_set_flag_view_Previews: PreviewProvider
{
    
    static var previews: some View
    {
        
        HStack
        {
            Option_set_flag_view(
                    name  : "Name",
                    is_on : true
                )
            
            Option_set_flag_view(
                    name  : "Very Long Name",
                    is_on : true
                )
        }
        .previewLayout(.fixed(width: 100, height: 80))
        
    }
    
}
