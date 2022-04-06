/**
 * \file    ble_nds_spec_notifications_view.swift
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
 *   "EC0A9302-4D24-11E7-B114-B2F933D5FE66":
 *            "Nonin Device Status"
 */
struct BLE_NDS_spec_notifications_view: View
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
            wrappedValue: BLE_NDS_spec_notifications_model(data_publisher)
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
    
    
    private var Status_fields_view : some View
    {
        
        HStack
        {
            Option_set_flag_view(
                    name: "Pulse oximeter",
                    is_on: model.sensor.contains(.pulse_oximeter)
                )
            Option_set_flag_view(
                    name: "No error",
                    is_on: model.device_error.contains(.no_error)
                )
            Option_set_flag_view(
                    name: "No Sensor",
                    is_on: model.device_error.contains(.no_sensor_connected)
                )
            Option_set_flag_view(
                    name: "Sensor fault",
                    is_on: model.device_error.contains(.sensor_fault)
                )
            Option_set_flag_view(
                    name: "System error",
                    is_on: model.device_error.contains(.system_error)
                )
        }
        .padding(.horizontal)
        
    }
    
    
    private var  Device_signal_view : some View
    {
        
        LazyVGrid(columns: grid_layout, alignment: .leading, spacing: 5)
        {
            
            BLE_signal_view(
                    id       : model.Counter.id,
                    name     : model.Counter.name,
                    units    : model.Counter.units,
                    gain     : model.Counter.gain,
                    value    : model.Counter.value,
                    show_physical_units : show_physical_units
                )
                .frame(width: box_width, height: box_height)
            
            BLE_signal_view(
                    id       : model.Battery_voltage.id,
                    name     : model.Battery_voltage.name,
                    units    : model.Battery_voltage.units,
                    gain     : model.Battery_voltage.gain,
                    value    : model.Battery_voltage.value,
                    show_physical_units : show_physical_units
                )
                .frame(width: box_width, height: box_height)
            
            BLE_signal_view(
                    id       : model.Battery_percentage.id,
                    name     : model.Battery_percentage.name,
                    units    : model.Battery_percentage.units,
                    gain     : model.Battery_percentage.gain,
                    value    : model.Battery_percentage.value,
                    show_physical_units : show_physical_units
                )
                .frame(width: box_width, height: box_height)
            
        }
        
    }
    
    
    // MARK: - Private state
    

    @StateObject private var model : BLE_NDS_spec_notifications_model
    
    private var grid_layout : [GridItem] = Array(
            repeating : .init(.flexible(), spacing: 5, alignment: .top),
            count     : 4
        )
    
    private var device_error_layout : [GridItem] = Array(
            repeating : .init(.flexible(), spacing: 5, alignment: .top),
            count     : 6
        )
    
    @State private var show_physical_units : Bool = true
    
    private let box_width     : CGFloat = 80
    private let box_height    : CGFloat = 60
    
    private let status_fields_height : CGFloat = 60
    
}


struct BLE_NDS_spec_notifications_view_Previews: PreviewProvider
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
        BLE_NDS_spec_notifications_view(
                data_publisher : dummy_model().$values
            )
            .previewInterfaceOrientation(.landscapeRight)
            .previewLayout(.fixed(width: 400, height: 350))
    }
    
}
