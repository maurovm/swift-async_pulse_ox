/**
 * \file    checkbox_button.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 3, 2022
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
struct Checkbox_button<T : Hashable>: View
{
    
    var body: some View
    {
        
        Button(action: self.action)
        {
            let selected = selection.contains(value)
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .renderingMode(.template)
                .antialiased(true)
                .padding(0)
                .foregroundColor( selected ? selected_color : unselected_color)
                .brightness(selected ? 0 : 0.5)
                .frame(width: size, height: size)
                .overlay(
                        Circle()
                            .stroke(unselected_color, lineWidth: 1)
                            .shadow(radius: 1)
                    )
        }
        .buttonStyle(PlainButtonStyle())
        
    }
    
    
    init(
            selection        : Binding<Set<T>>,
            value            : T,
            size             : CGFloat = 20,
            selected_color   : Color   = .green,
            unselected_color : Color   = .gray,
            border_color     : Color   = .gray,
            action           : @escaping () -> Void
        )
    {
        
        self._selection       = selection
        self.value            = value
        self.size             = size
        self.selected_color   = selected_color
        self.unselected_color = unselected_color
        self.border_color     = border_color
        self.action           = action
        
    }
    
    
    // MARK: - Private state
    
    
    @Binding private var selection : Set<T>
    
    private var value            : T
    private let action           : () -> Void
    private let size             : CGFloat
    private let selected_color   : Color
    private let unselected_color : Color
    private let border_color     : Color
    
}



struct Checkbox_button_Previews: PreviewProvider
{
    
    static var previews: some View
    {
        VStack
        {
            Checkbox_button(
                    selection : .constant([1, 2, 3]),
                    value     : 1 ,
                    action    : {}
                )
            
            Checkbox_button(
                    selection : .constant([1, 2, 3]),
                    value     : 5 ,
                    action    : {}
                )
        }
        .previewLayout(.fixed(width: 50, height: 70))
    }
    
}
