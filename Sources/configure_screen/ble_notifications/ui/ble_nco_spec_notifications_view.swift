/**
 * \file    ble_nco_spec_notifications_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 10, 2022
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
 *   "0AAD7EA0-0D60-11E2-8E3C-0002A5D5C51B":
 *            "Nonin Continuous Oximetery Characteristic"
 */
struct BLE_NCO_spec_notifications_view: View
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
    init(  data_publisher : Published<ASB_data>.Publisher )
    {
        
        _model = StateObject(
            wrappedValue: BLE_NCO_spec_notifications_model(data_publisher)
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
                    name: "Weak signal",
                    is_on: model.status.contains(.weak_signal)
                )
            Option_set_flag_view(
                    name: "Smart Pointer",
                    is_on: model.status.contains(.smart_point)
                )
            Option_set_flag_view(
                    name: "Searching",
                    is_on: model.status.contains(.searching)
                )
            Option_set_flag_view(
                    name: "Sensor connected",
                    is_on: model.status.contains(.sensor_connected)
                )
            Option_set_flag_view(
                    name: "Low battery",
                    is_on: model.status.contains(.low_battery)
                )
            Option_set_flag_view(
                    name: "Encrypted",
                    is_on: model.status.contains(.encrypted)
                )
            
            Spacer()
        }
        .padding(.horizontal)
        
    }
    
    
    private var Device_signal_view : some View
    {
        
        LazyVGrid(columns: grid_layout, alignment: .leading, spacing: 5)
        {
            BLE_signal_view(
                    id       : model.HR.id,
                    name     : model.HR.name,
                    units    : model.HR.units,
                    gain     : model.HR.gain,
                    value    : model.HR.value,
                    show_physical_units : show_physical_units
                )
                .frame(width: box_width, height: box_height)
            
            BLE_signal_view(
                    id       : model.SpO2.id,
                    name     : model.SpO2.name,
                    units    : model.SpO2.units,
                    gain     : model.SpO2.gain,
                    value    : model.SpO2.value,
                    show_physical_units : show_physical_units
                )
                .frame(width: box_width, height: box_height)
            
            BLE_signal_view(
                    id       : model.PAI.id,
                    name     : model.PAI.name,
                    units    : model.PAI.units,
                    gain     : model.PAI.gain,
                    value    : model.PAI.value,
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
                    id       : model.Counter.id,
                    name     : model.Counter.name,
                    units    : model.Counter.units,
                    gain     : model.Counter.gain,
                    value    : model.Counter.value,
                    show_physical_units : show_physical_units
                )
                .frame(width: box_width, height: box_height)
            
        }
        
    }
    
    
    // MARK: - Private state
    

    @StateObject private var model : BLE_NCO_spec_notifications_model
    
    private var grid_layout : [GridItem] = Array(
            repeating : .init(.flexible(), spacing: 5, alignment: .top),
            count     : 4
        )
    
    private var status_layout : [GridItem] = Array(
            repeating : .init(.flexible(), spacing: 5, alignment: .top),
            count     : 6
        )
    
    @State private var show_physical_units : Bool = true
    
    private let box_width     : CGFloat = 75
    private let box_height    : CGFloat = 60
    
    private let status_fields_height : CGFloat = 60
    
}


struct BLE_NCO_spec_notifications_view_Previews: PreviewProvider
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
        
        BLE_NCO_spec_notifications_view(
                data_publisher : dummy_model().$values
            )
            .previewInterfaceOrientation(.landscapeRight)
            .previewLayout(.fixed(width: 500, height: 300))
        
    }
    
}
