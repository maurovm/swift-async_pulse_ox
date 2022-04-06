/**
 * \file    ble_nds_spec_notifications_model.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 2, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import Combine
import AsyncBluetooth
import SensorRecordingUtils


/**
 * Data model for the notification data from the Characteritic:
 *
 *   "EC0A9302-4D24-11E7-B114-B2F933D5FE66":
 *            "Nonin Device Status"
 */
@MainActor
class BLE_NDS_spec_notifications_model : ObservableObject
{
    
    // MARK: - Data to diplay
    
    
    @Published private(set) var sensor  = BLE_NDS_spec_decoder.Sensor_type(rawValue: 0)
    
    @Published private(set) var device_error  = BLE_NDS_spec_decoder.Device_Error(rawValue: 0)

    
    @Published private(set) var Battery_voltage    : BLE_signal
    @Published private(set) var Battery_percentage : BLE_signal
    @Published private(set) var Counter            : BLE_signal
    
    @Published public var show_decode_alert = false
    
    private(set) var decode_error: ASB_error?
    
    
    /**
     * Class initialiser
     */
    init( _  data_publisher :  Published<ASB_data>.Publisher )
    {
        
        if let signal = decoder.get_signal(.battery_voltage)
        {
            Battery_voltage = signal
        }
        else
        {
            Battery_voltage = BLE_signal(
                    type      : .battery_voltage,
                    units     : "unknown",
                    gain      : 0,
                    frequency : 1,
                    value     : 0
                )
        }
        
        if let signal = decoder.get_signal(.battery_percentage)
        {
            Battery_percentage = signal
        }
        else
        {
            Battery_percentage = BLE_signal(
                    type      : .battery_percentage,
                    units     : "unknown",
                    gain      : 0,
                    frequency : 1,
                    value     : 0
                )
        }
        
        if let signal = decoder.get_signal(.counter)
        {
            Counter = signal
        }
        else
        {
            Counter = BLE_signal(
                    type      : .counter,
                    units     : "unknown",
                    gain      : 0,
                    frequency : 1,
                    value     : 0
                )
        }
        
        data_subscription = data_publisher.sink
        {
            [weak self] data in
            self?.decode(data)
        }
        
    }
    
    
    deinit
    {
        data_subscription?.cancel()
        data_subscription = nil
    }
    
    
    // MARK: - Private state
    
    
    private var data_subscription : AnyCancellable?
    private var decoder           = BLE_NDS_spec_decoder()
    
    
    // MARK: - Private interface
    
    
    private func decode( _ data: ASB_data )
    {
        
        do
        {
            if let ble_output = try decoder.decode(data) as? BLE_NDS_spec_decoder.Output
            {
                sensor       = ble_output.sensor
                device_error = ble_output.error
                
                Battery_voltage.value    = ble_output.battery_voltage
                Battery_percentage.value = ble_output.battery_percentage
                Counter.value            = ble_output.counter
            }
        }
        catch
        {
            decode_error = ASB_error.decode_data(
                    description: "\(error.localizedDescription)"
                )
            show_decode_alert = true
        }
        
    }
    
}
