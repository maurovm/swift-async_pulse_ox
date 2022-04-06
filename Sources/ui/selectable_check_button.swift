/**
 * \file    selectable_check_button.swift
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


/**
 * A selection Button that appears like a checkbox
 */
struct Selectable_check_button: View
{
    
    var body: some View
    {
        
        Button(action: self.action)
        {
            if enabled
            {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .renderingMode(.template)
                    .antialiased(true)
                    .padding(0)
                    .foregroundColor( is_selected ? selected_color : unselected_color)
                    .brightness(is_selected ? 0 : 0.5)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(unselected_color, lineWidth: 1)
                            .shadow(radius: 1)
                    )
            }
            else
            {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .renderingMode(.template)
                    .antialiased(true)
                    .padding(0)
                    .foregroundColor( is_selected ? selected_color : unselected_color)
                    .brightness(is_selected ? 0 : 0.5)
                    .frame(width: size, height: size)
            }
        }
        .buttonStyle(PlainButtonStyle())
        
    }
    
    
    init(
            is_selected      : Bool,
            enabled          : Bool    = false,
            action           : @escaping () -> Void = {},
            size             : CGFloat = 20,
            selected_color   : Color   = .green,
            unselected_color : Color   = .gray,
            border_color     : Color   = .gray
        )
    {
        
        self.is_selected      = is_selected
        self.enabled          = enabled
        self.action           = action
        self.size             = size
        self.selected_color   = selected_color
        self.unselected_color = unselected_color
        self.border_color     = border_color
        
    }
    
    
    // MARK: - Private state
    
    
    private var is_selected      : Bool
    private let enabled          : Bool
    private let action           : () -> Void
    private let size             : CGFloat
    private let selected_color   : Color
    private let unselected_color : Color
    private let border_color     : Color
    
}


struct Selectable_check_button_Previews: PreviewProvider
{
    
    static var previews: some View
    {
        
        VStack
        {
            Selectable_check_button(
                    is_selected  : true ,
                    action       : {}
                )
        
            Selectable_check_button(
                    is_selected  : false ,
                    action       : {}
                )
        }
        .previewLayout(.fixed(width: 50, height: 70))
        
    }
    
}
