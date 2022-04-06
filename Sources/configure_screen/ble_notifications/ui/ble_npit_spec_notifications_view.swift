/**
 * \file    ble_npit_spec_notifications_view.swift
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
import AsyncBluetooth


/**
 * Display the data that is sent by the Characteritic:
 *
 * "34E27863-76FF-4F8E-96F1-9E3993AA6199" : "Nonin Pulse Interval Time"
 */
struct BLE_NPIT_spec_notifications_view: View
{
    
    var body: some View
    {
        
        ScrollView(.vertical)
        {
            
            VStack
            {
                Physical_toggle_view
                Status_fields_view
                    .frame(minHeight: status_fields_height)
                Divider()
                Device_signal_view
                Spacer()
            }
            
        }
        .alert("Error",
               isPresented: $model.show_decode_alert,
               presenting : model.decode_error,
               actions    :
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
            data_publisher : Published<ASB_data>.Publisher,
            pulses         : [NPIT_pulse_signal]      = []
        )
    {
        
        _model = StateObject( wrappedValue: BLE_NPIT_spec_notifications_model(
                data_publisher, pulses: pulses
            ))
        
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
                        .frame(alignment: .trailing)
                }
                .padding(.horizontal)
                .frame(maxWidth: 200)
        }
        
    }
    
    
    private var Status_fields_view : some View
    {
        
        HStack
        {
            Option_set_flag_view(
                    name: "Invalid signal",
                    is_on: model.status.contains(.invalid_signal)
                )
                .frame(width: status_fields_width)
            
            Option_set_flag_view(
                    name: "HR too high",
                    is_on: model.status.contains(.pulse_rate_high)
                )
                .frame(width: status_fields_width)
        
            BLE_signal_view(
                    id       : model.Counter.id,
                    name     : model.Counter.name,
                    units    : model.Counter.units,
                    gain     : model.Counter.gain,
                    value    : model.Counter.value,
                    show_physical_units : show_physical_units
                )
                .frame(width: status_fields_width * 1.4)
            
            Spacer()
        }
        
    }
    
    
    private var  Device_signal_view : some View
    {
        
        LazyVGrid(columns: grid_layout, alignment: .leading, spacing: 5)
        {
            ForEach(model.all_pulses)
            {
                pulse in
                
                NPIT_pulse_view(
                        id             : pulse.id,
                        bad_pulse_flag : pulse.bad_pulse_flag,
                        PAI            : pulse.PAI,
                        pulse_time     : pulse.pulse_time,
                        show_physical_units : show_physical_units
                    )
                    .frame(minHeight: pulse_view_height)
            }
        }
        
    }
    
    
    // MARK: - Private state
    

    @StateObject private var model : BLE_NPIT_spec_notifications_model
    
    private var grid_layout : [GridItem] = Array(
            repeating : .init(.flexible(), spacing: 5, alignment: .top),
            count     : 2
        )
    
    @State private var show_physical_units : Bool = true
    
    private let status_fields_width  : CGFloat = 50
    private let status_fields_height : CGFloat = 60
    private let pulse_view_height    : CGFloat = 60
    
}



struct BLE_NPIT_spec_notifications_view_Previews: PreviewProvider
{
    
    /**
     * Dummy data to be able to generate the Preview
     */
    class dummy_model: ObservableObject
    {
        
        @Published var values = ASB_data()
        
        var pulses : [NPIT_pulse_signal] = []
        
        let number_of_pulses = 6
        
        init()
        {
            
            let decoder = BLE_NPIT_spec_decoder()
            
            for _ in 0..<number_of_pulses
            {
                if let pai_signal = decoder.get_signal(.PAI)  ,
                   let pulse_signal = decoder.get_signal(.pulse_time)
                {
                    pulses.append( NPIT_pulse_signal(
                            bad_pulse_flag: true,
                            PAI       : pai_signal,
                            pulse_time: pulse_signal
                        ))
                }
            }
            
        }
        
    }
    
    
    static var previews: some View
    {
        BLE_NPIT_spec_notifications_view(
                data_publisher : dummy_model().$values,
                pulses         : dummy_model().pulses
            )
            .previewInterfaceOrientation(.landscapeRight)
            .previewLayout(.fixed(width: 500, height: 300))
    }
    
}
