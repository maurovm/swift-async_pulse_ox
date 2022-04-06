/**
 * \file    pulse_ox_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 7, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import SensorRecordingUtils


/**
 * Main View to show the vital signs of the Nonin pulse oximeter
 */
@MainActor
public struct Pulse_ox_view: View
{
    
    public var body: some View
    {
        
        HStack(alignment: .center)
        {
            
            Sensor_label_view( label : "Nonin", is_vertical : false )
                .frame(width: sensor_label_width)

            
            Divider().panel_style()

            Spacer()
            
            
            if manager.device_state == .streaming
            {
                Vital_sign_numerics_view(manager.vital_signs_display_model)
            }
            else
            {
                Sensor_recording_state_view
            }
            
            
            Spacer()
            
            Divider().panel_style()
            
            
            Sensor_status
                .frame(width: 50)
                .padding(5)
        }
        
    }
    
    
    public init(_ manager: Recording_manager)
    {
        
        _manager = ObservedObject(wrappedValue: manager)
        
        _numerics = ObservedObject(
                wrappedValue: manager.vital_signs_display_model
            )
        
    }
    
    
    // MARK: - Body Views
    
    
    private var Sensor_recording_state_view: some View
    {
        
        HStack
        {
            
            Text(recording_state_message)
                .font(.system(.body)).padding(.horizontal)
            
            
            switch manager.device_state
            {
                case .disconnected:
                    
                    Image(systemName: "multiply.circle")
                        .font(.system(.title))
                        .padding()
                    
                default:
                    
                    ProgressView()
                        .scaleEffect(x: 2, y: 2, anchor: .center)
                        .padding()
            }
            
        }
        .background(.white)
        .cornerRadius(10)
        
    }
    
    
    private var Sensor_status: some View
    {
        VStack
        {
            if manager.device_state == .streaming  ,
               let battery_percentage = numerics.battery_percentage
            {
                Battery_percentage_view(
                        device_id      : manager.identifier,
                        percentage     : battery_percentage,
                        show_device_id : false
                    )
                .padding(.vertical, 5)
            }
            else
            {
                EmptyView()
            }
        }
        
    }
    
    
    // MARK: - Private state
    
    
    @ObservedObject  private var manager  : Recording_manager
    @ObservedObject  private var numerics : Vital_sign_numerics_model
 
    private let sensor_label_width : CGFloat = 25.0
    
    
    private var recording_state_message : String
    {
        let message : String
        
        switch manager.device_state
        {
            case .disconnected:
                message = "Disconnected"
                
            case .connecting:
                message = "Connecting..."
                
            case .stopping:
                message = "Stopping..."
                
            case .disconnecting:
                message = "Disconnecting..."
                
            default:
                message = ""
        }
        
        return message
    }
    
}


fileprivate extension Divider
{
    
    func panel_style() -> some View
    {
        self.background(.yellow)
            .clipped()
            .padding(.vertical)
    }
    
}



struct Nonin_view_Previews: PreviewProvider
{
    
    static let interface_orientation: UIDeviceOrientation = .landscapeRight
    static let preview_mode: Device.Content_mode = .scale_to_fill
    static let timeout : Double = 10
    static let nco_decoder = BLE_NCO_spec_decoder()
    
    static let vital_signs : [BLE_signal] = nco_decoder.get_minimum_numerics()
    
    
    static var previews: some View
    {
        Group
        {
            
            Pulse_ox_view(
                Recording_manager(
                        orientation        : interface_orientation,
                        preview_mode       : preview_mode,
                        device_state       : .disconnected,
                        connection_timeout : timeout
                    )
                )
            
            
            Pulse_ox_view(
                Recording_manager(
                        orientation        : interface_orientation,
                        preview_mode       : preview_mode,
                        device_state       : .connecting,
                        connection_timeout : timeout
                    )
                )
            
            
            Pulse_ox_view(
                Recording_manager(
                        orientation        : interface_orientation,
                        preview_mode       : preview_mode,
                        device_state       : .streaming,
                        connection_timeout : timeout,
                        vital_signs_display_model : Vital_sign_numerics_model(
                                vital_signs, battery_percentage: 36
                            )
                    )
                )
            
            
            Pulse_ox_view(
                Recording_manager(
                        orientation        : interface_orientation,
                        preview_mode       : preview_mode,
                        device_state       : .stopping,
                        connection_timeout : timeout
                    )
                )
            
            
            Pulse_ox_view(
                Recording_manager(
                        orientation        : interface_orientation,
                        preview_mode       : preview_mode,
                        device_state       : .disconnecting,
                        connection_timeout : timeout
                    )
                )
        }
        .background(.cyan)
        .previewLayout(.fixed(width: 600, height: 70))
        
    }
    
}
