/**
 * \file    ble_nppg_spec_notifications_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 12, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import AsyncBluetooth
import WaveformPlotter


/**
 * Display the data that is sent by the Characteritic:
 *
 *   "EC0A883A-4D24-11E7-B114-B2F933D5FE66":  "Nonin PPG"
 */
struct BLE_NPPG_spec_notifications_view: View
{
    
    var body: some View
    {
        
        VStack
        {
            
            HStack
            {
                BLE_signal_view(
                        id       : model.Counter.id,
                        name     : model.Counter.name,
                        units    : model.Counter.units,
                        gain     : model.Counter.gain,
                        value    : model.Counter.value
                    )
                    .frame(width: box_width, height: box_height)
                
                Spacer()
            }
            
            Waveform_signal_view(
                    data        : model.values,
                    write_index : model.next_write_index,
                    y_min       : model.values_min,
                    y_max       : model.values_max,
                    x_min       : model.t_min,
                    x_max       : model.t_max,
                    signal_name : "PPG"
                )
                .padding(.vertical)
            
        }
        .alert("Error",
               isPresented: $model.show_decode_alert,
               presenting : model.decode_error,
               actions:
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
    
    /**
     * Class initialiser
     */
    init(
            display_seconds : Int = 10,
            data_publisher  : Published<ASB_data>.Publisher
        )
    {
        
        self.display_seconds = display_seconds
        
        _model = StateObject( wrappedValue: BLE_NPPG_spec_notifications_model(
                data_publisher, buffer_seconds: display_seconds
            ))
        
    }
    
    
    // MARK: - Private state
    

    // Display 10 seconds worth of data
    private let display_seconds : Int
    
    @StateObject private var model : BLE_NPPG_spec_notifications_model
    
    private let box_width  : CGFloat = 120
    private let box_height : CGFloat = 70
    
}



struct BLE_NPPG_spec_notifications_view_Previews: PreviewProvider
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
        
        BLE_NPPG_spec_notifications_view(
                data_publisher : dummy_model().$values
            )
            .previewInterfaceOrientation(.landscapeRight)
            .previewLayout(.fixed(width: 400, height: 300))
    }
    
}
