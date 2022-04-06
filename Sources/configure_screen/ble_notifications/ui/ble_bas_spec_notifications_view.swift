/**
 * \file    ble_bas_spec_notifications_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 16, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import AsyncBluetooth


/**
 * Display the data that is sent by the Characteritic:
 *
 *   2A19: "Battery Level"
 */
struct BLE_BAS_spec_notifications_view: View
{
    
    var body: some View
    {
        
        ScrollView(.vertical)
        {
            
            VStack
            {
                Physical_toggle_view
                
                Divider()
                
                Device_signal_view
                
                Spacer()
            }
            
        }
        .alert( "Error",
                isPresented: $model.show_decode_alert,
                presenting : model.decode_error,
                actions:
                {
                    _ in
                    Button( "OK",  action: {} )
                },
                message:
                {
                    error_type in

                    switch error_type
                    {
                        case .decode_data(let message):
                            Text("Can't parse value: \(message)")
                            
                        default:
                            Text("Unknown error")
                    }
                }
            )
        
    }
    
    /**
     * Class initialiser
     */
    init( data_publisher : Published<ASB_data>.Publisher )
    {
        _model = StateObject(
            wrappedValue: BLE_BAS_spec_notifications_model(data_publisher)
            )
    }
    
    
    // MARK: - Private Views
    
    
    private var Physical_toggle_view : some View
    {
        HStack
        {
            Spacer()
            Toggle(isOn: $show_physical_units)
            {
                Text("Physical units:")
                    .font(.subheadline)
                    .frame(alignment: .trailing)
            }
                .padding(.horizontal)
                .frame(maxWidth: 200)
        }
    }
    
    
    private var  Device_signal_view : some View
    {
        
        HStack
        {
            BLE_signal_view(
                id       : model.Battery_percentage.id,
                name     : model.Battery_percentage.name,
                units    : model.Battery_percentage.units,
                gain     : model.Battery_percentage.gain,
                value    : model.Battery_percentage.value,
                show_physical_units : show_physical_units
            )
            .frame(width: box_width, height: box_height)
         
            Spacer()
        }
        
    }
    
    
    // MARK: - Private state
    

    @StateObject private var model : BLE_BAS_spec_notifications_model
    
    @State private var show_physical_units : Bool = true
    
    private let box_width  : CGFloat = 80
    private let box_height : CGFloat = 60
    
}


struct BLE_BAS_spec_notifications_view_Previews: PreviewProvider
{
    
    /**
     * Dummy data to be able to generate the Preview
     */
    class dummy_model: ObservableObject
    {
        @Published var values = ASB_data()
    }
    
    static var previews: some View
    {
        BLE_BAS_spec_notifications_view(
                data_publisher : dummy_model().$values
            )
        .previewInterfaceOrientation(.landscapeRight)
        .previewLayout(.fixed(width: 400, height: 350))
    }
    
}
