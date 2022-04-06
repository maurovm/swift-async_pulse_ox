/**
 * \file    toggle_button.swift
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


// FIXME: There has to be a better way to implement the behaviour of this class
/**
 * A selection Button that is typically used in List rows to toggle state
 *
 * The `action` will only be executed in the inactive state
 */
struct Toggle_button <T : Equatable>: View
{
    
    var body: some View
    {
        
        ZStack(alignment: .leading)
        {
            
            Button( action: (status == .enabled) ? self.action : {} )
            {
                if status == .selected
                {
                    Text(text)
                        .modifier(
                            Active_text_style(
                                selected_color: active_color,
                                selected_text_color: inactive_text_color
                            )
                        )
                }
                else
                {
                    Text(text)
                        .modifier( Inactive_text_style() )
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            
            if status == .processing || status == .disabled
            {
                RoundedRectangle(cornerRadius: corner_radius)
                    .foregroundColor(.white)
                    .opacity(0.9)
                
            }
            
            
            if status == .processing
            {
                ProgressView()
                    .progressViewStyle(
                        CircularProgressViewStyle(tint: active_color)
                    )
                    .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .trailing
                        )
                    .foregroundColor(.black)
                    .cornerRadius(corner_radius)
                    .padding(.horizontal)
                
                Text(processing_text)
                    .font(.footnote)
                    .foregroundColor(.black)
                    .brightness(0.3)
                    .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .center
                        )
            }
            
        }
        
    }
    
    
    init(
            text                : String,
            id                  : T,
            active_id           : T?      = nil,
            is_processing       : Bool    = false,
            processing_text     : String  = "Loading ...",
            active_color        : Color   = .blue,
            inactive_text_color : Color   = .white,
            action              : @escaping () -> Void
        )
    {
        self.text =  text.isEmpty ?  "\(id)" : text
        
        self.identifier          = id
        self.active_identifier   = active_id
        self.is_processing       = is_processing
        
        self.processing_text     = processing_text
        self.active_color        = active_color
        self.inactive_text_color = inactive_text_color
        self.action              = action
                   
        
        if self.identifier == self.active_identifier
        {
            if self.is_processing
            {
                status = .processing
            }
            else
            {
                status = .selected
            }
        }
        else
        {
            if self.is_processing
            {
                status = .disabled
            }
            else
            {
                status = .enabled
            }
        }
        
    }
    
    
    // MARK: - Private state
    
    
    private let text                : String
    
    private let identifier          : T
    private let active_identifier   : T?
    private let is_processing       : Bool
    
    private var processing_text     : String
    private let action              : () -> Void
    private let active_color        : Color
    private let inactive_text_color : Color
    private let corner_radius       : CGFloat = 10
    
    private var status : Toggle_button.Button_status

    
    /**
     * The computed status of the Button
     */
    private enum Button_status
    {
        case enabled
        case processing
        case disabled
        case selected
    }
    
}


fileprivate struct Active_text_style: ViewModifier
{
    let selected_color      : Color
    let selected_text_color : Color
    
    func body(content: Content) -> some View
    {
        content
            .foregroundColor(selected_text_color)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.leading, 10)
            .background(selected_color)
            .brightness(0.2)
            .clipShape(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            .font(.footnote)
    }
}


fileprivate struct Inactive_text_style: ViewModifier
{
    func body(content: Content) -> some View
    {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.leading, 10)
            .font(.footnote)
    }
}



struct Toggle_button_Previews: PreviewProvider
{
    
    static var previews: some View
    {
        
        VStack(alignment: .center, spacing: 10)
        {
            Toggle_button(
                    text          : "Button selected",
                    id            : 1,
                    active_id     : 1,
                    is_processing : false,
                    action        : {}
                )

            Divider()
            
            Toggle_button(
                    text          : "Button processing",
                    id            : 1,
                    active_id     : 1,
                    is_processing : true,
                    action        : {}
                )
            
            Divider()
            
            Toggle_button(
                    text          : "Button enabled",
                    id            : 1,
                    active_id     : 2,
                    is_processing : false,
                    action        : {}
                )
            
            Divider()
            
            Toggle_button(
                    text          : "Button disabled",
                    id            : 1,
                    active_id     : 2,
                    is_processing : true,
                    action        : {}
                )
        }
        .previewLayout(.fixed(width: 250, height: 200))
        .previewInterfaceOrientation(.landscapeRight)
        
    }
    
}
