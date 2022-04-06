/**
 * \file    characteristic_detail_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 6, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import SensorRecordingUtils
import CoreBluetooth
import AsyncBluetooth


public struct Characteristic_detail_view: View
{
    
    private func get_grid_layout(
            _  first_panel_width  : CGFloat,
            _  second_panel_width : CGFloat
        ) -> [GridItem]
    {
        
        var grid_layout : [GridItem] = []
        
        if is_landscape
        {
            grid_layout.append( .init(
                .fixed(first_panel_width), spacing: 0, alignment: .center
                ))
            
            
            grid_layout.append( .init(
                .fixed(second_panel_width), spacing: 0, alignment: .center
                ))
        }
        else
        {
            grid_layout.append( .init(
                .fixed(first_panel_width), spacing: 0, alignment: .center
                ))
        }
        
        return grid_layout
        
    }
    
    
    public var body: some View
    {
        
        GeometryReader
        {
            
            geo in
            
            
            // Grid layout configuration
            
            
            let first_panel_width  = is_landscape ?
                ( geo.size.width * 0.35 ) : geo.size.width
            
            let second_panel_width = is_landscape ?
                ( geo.size.width * 0.65 ) : geo.size.width
            
            let first_panel_height  = is_landscape ? geo.size.height : ( geo.size.height * 0.35 )
            
            let second_panel_height = is_landscape ? geo.size.height : ( geo.size.height * 0.65 )
                        
            let grid_layout = get_grid_layout(first_panel_width, second_panel_width)
            
            
            // The actual grid
            
            
            LazyVGrid(columns: grid_layout, alignment: .center, spacing: 0)
            {
                Summary_view
                    .frame(width: first_panel_width, height: first_panel_height)
                
                Detail_view
                    .frame(width: second_panel_width, height: second_panel_height)
            }
            
        }
        .toolbar
        {
            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button( "Close", role: .cancel)
                {
                    model.end_session()
                    dismiss()
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
            }
        }
        .navigationBarTitle("Characteristic detail")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(false)
        
    }
    
    
    /**
     * Class initialiser
     */
    public init(
            peripheral         : ASB_peripheral,
            cb_characteristic  : CBCharacteristic
        )
    {
        
        date_formatter.dateFormat = "HH:mm:ss"
        
        _model = StateObject(
                wrappedValue:Characteristic_detail_model(
                        peripheral     : peripheral,
                        characteristic : cb_characteristic
                    )
            )
        
    }
    
    
    // MARK: - Private body Views
    
    
    @ViewBuilder
    private var Summary_view: some View
    {
        
        List
        {
            HStack
            {
                Text("Characteristic: ").font(.body)
            }
            Text(model.name).font(.caption)
            
            Section(header: Text("Properties"))
            {
                ForEach(model.all_properties)
                {
                    Toggle($0.name, isOn: .constant($0.enabled))
                }
            }
        }
        .listStyle(.plain)
        
    }
    
    
    private var Detail_view: some View
    {
        
        VStack
        {
            if model.contains(property: .notify)
            {
                Notifying_view
            }
            
            if model.contains(property: .read)
            {
                Divider()
                Read_value_view
            }
        }
        
    }
    
    
    private var Notifying_view : some View
    {
        
        VStack(spacing: 10)
        {
            
            HStack
            {   
                Spacer()
                
                Toggle("Notifying?", isOn: .constant(model.is_notifying) )
            
                let message = model.is_notifying ? "Stop notifications" :
                    "Start notifications"
                Button(
                    role:model.is_notifying ? .destructive : .cancel,
                    action : { model.toggle_notification() },
                    label  : { Text(message) }
                    )
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Text( date_formatter.string(from: model.notification_update_timestamp) )
                    .font(.caption)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
            
            Divider()
            
            switch model.label
            {
                case .battery_level:
                    BLE_BAS_spec_notifications_view(
                            data_publisher: model.$notification_value
                        )
                    
                case .heart_rate:
                    BLE_HRS_spec_notifications_view(
                            data_publisher: model.$notification_value
                        )

                case .nonin_pulse_interval_time:
                    BLE_NPIT_spec_notifications_view(
                            data_publisher: model.$notification_value
                        )

                case .nonin_continuous_oximetry:
                    BLE_NCO_spec_notifications_view(
                            data_publisher: model.$notification_value
                        )

                case .nonin_PPG:
                    BLE_NPPG_spec_notifications_view(
                            data_publisher: model.$notification_value
                        )

                case .nonin_device_status:
                    BLE_NDS_spec_notifications_view(
                            data_publisher: model.$notification_value
                        )

                default:

                    Text("Generic Notification Display").font(.title)
                    
                    HStack
                    {
                        let data_value = String(data: model.notification_value.data, encoding: String.Encoding.utf8)
                            ?? "?"
                        Text( data_value )
                            .font(.caption)
                            .padding()
                            .frame(minWidth: 90)
                            .border(Color.black, width: 1)

                        if model.units.isEmpty == false
                        {
                            Text(model.units)
                                .font(.caption)
                                .padding()
                                .border(Color.black, width: 1)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        
    }
    
    
    private var Read_value_view : some View
    {
        
        List
        {
            Section(header: Text("Data value"))
            {
                HStack
                {
                    Button("Read")
                    {
                        Task
                        {
                            await model.read_value()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Spacer()
                    
                    Text( date_formatter.string(from: Date()) )
                        .font(.footnote)
                }
                HStack
                {
                    Text(model.value)
                        .font(.caption)
                        .padding()
                        .frame(minWidth: 90, maxWidth: .infinity, alignment: .leading)
                        .border(Color.black, width: 1)
                    
                    if model.units.isEmpty == false
                    {
                        Text(model.units)
                            .font(.caption)
                            .padding()
                            .border(Color.black, width: 1)
                    }
                }
            }
        }
        .listStyle(.inset)
        
    }
    
    
    // MARK: - Private state
    
    
    private let date_formatter  = DateFormatter()
    private let number_of_panels = 2
    
    
    @StateObject private var model : Characteristic_detail_model
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.horizontalSizeClass) private var horizontal_size
    
    
    
    private var is_landscape : Bool
    {
        horizontal_size == .regular
    }
    
}

