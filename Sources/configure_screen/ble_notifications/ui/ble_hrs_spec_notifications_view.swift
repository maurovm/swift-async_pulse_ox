/**
 * \file    ble_hrs_spec_notifications_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 8, 2022
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
 *   2A37 : "Hearr Rate Measurement"
 */
struct BLE_HRS_spec_notifications_view: View
{
    
    var body: some View
    {
        
        VStack
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
            LazyVGrid(columns: grid_layout, alignment: .leading, spacing: 5)
            {
                ForEach(model.all_vital_signs)
                {
                    vital_sign in
                    
                    BLE_signal_view(
                            id        : vital_sign.id,
                            name      : vital_sign.name,
                            units     : vital_sign.units,
                            gain      : vital_sign.gain,
                            value     : vital_sign.value,
                            show_physical_units : show_physical_units
                        )
                        .frame(width: 90, height: 80)
                }
            }
            
            Spacer()
            
        }
        .alert("Error",
               isPresented : $model.show_decode_alert,
               presenting  : model.decode_error,
               actions     :
               {
                    _ in
                    Button("OK",  action: {})
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
    
    init(
            data_publisher : Published<ASB_data>.Publisher,
            vital_signs    : [BLE_signal]  = []
        )
    {
        
        _model = StateObject( wrappedValue: BLE_HRS_spec_notifications_model(
                data_publisher, vital_signs: vital_signs
            ))
        
    }
    
    
    // MARK: - Private state
    

    @StateObject var model : BLE_HRS_spec_notifications_model
    
    var grid_layout : [GridItem] = Array(
            repeating : .init(.flexible(), spacing: 5, alignment: .top),
            count     : 4
        )
    
    @State private var show_physical_units : Bool = true
    
}


struct BLE_HRS_spec_notifications_view_Previews: PreviewProvider
{
    
    /**
     * Dummy data to be able to generate the Preview
     */
    class dummy_model: ObservableObject
    {
        @Published var values = ASB_data()
        
        var vital_signs_data : [BLE_signal] = []
        
        init()
        {
            // Generate signals so they can get different id's and
            // SwiftUI can identify them individually
            vital_signs_data.append( BLE_signal(
                    type      : .HR,
                    units     : "bpm",
                    gain      : 1,
                    frequency : 1,
                    value     : Int.random(in: 1..<250)
                ))
            for _ in 0..<6
            {
                vital_signs_data.append( BLE_signal(
                        type      : .RR_interval,
                        units     : "ms",
                        gain      : (1000.0/104.0),
                        frequency : 1,
                        value     : Int.random(in: 200..<1000)
                    ))
            }
        }
    }
    
    static var previews: some View
    {
        BLE_HRS_spec_notifications_view(
                data_publisher : dummy_model().$values,
                vital_signs    : dummy_model().vital_signs_data
            )
            .previewInterfaceOrientation(.landscapeRight)
            .previewLayout(.fixed(width: 400, height: 350))
    }
    
}
