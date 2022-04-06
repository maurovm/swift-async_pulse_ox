/**
 * \file    ble_nco_spec_notifications_model.swift
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
import Combine
import AsyncBluetooth
import SensorRecordingUtils


/**
 * Data model for the notification data from the Characteritic:
 *
 *   "0AAD7EA0-0D60-11E2-8E3C-0002A5D5C51B":
 *            "Nonin Continuous Oximetery Characteristic"
 */
@MainActor
final class BLE_NCO_spec_notifications_model : ObservableObject
{
    
    // MARK: - Data to diplay
    
    
    @Published private(set) var status  = BLE_NCO_spec_decoder.Status(rawValue: 0)
    
    @Published private(set) var HR   : BLE_signal
    @Published private(set) var SpO2 : BLE_signal
    @Published private(set) var PAI  : BLE_signal
    
    @Published private(set) var Battery_voltage : BLE_signal
    @Published private(set) var Counter         : BLE_signal
    
    @Published public var show_decode_alert = false
    
    private(set) var decode_error: ASB_error?
    
    
    /**
     * Class initialiser
     */
    init( _  data_publisher :  Published<ASB_data>.Publisher )
    {
        
        if let signal = decoder.get_signal(.HR)
        {
            HR = signal
        }
        else
        {
            HR = BLE_signal(
                    type      : .HR,
                    units     : "unknown",
                    gain      : 0,
                    frequency : 1,
                    value     : 0
                )
        }
        
        if let signal = decoder.get_signal(.SpO2)
        {
            SpO2 = signal
        }
        else
        {
            SpO2 = BLE_signal(
                    type      : .SpO2,
                    units     : "unknown",
                    gain      : 0,
                    frequency : 1,
                    value     : 0
                )
        }
        
        if let signal = decoder.get_signal(.PAI)
        {
            PAI = signal
        }
        else
        {
            PAI = BLE_signal(
                    type      : .PAI,
                    units     : "unknown",
                    gain      : 0,
                    frequency : 1,
                    value     : 0
                )
        }
        
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
    private var decoder           = BLE_NCO_spec_decoder()
    
    
    // MARK: - Private interface
    
    
    private func decode( _ data: ASB_data )
    {
        
        do
        {
            if let ble_output = try decoder.decode(data) as? BLE_NCO_spec_decoder.Output
            {
                status = ble_output.status

                HR.value        = ble_output.HR
                SpO2.value      = ble_output.SpO2
                PAI.value       = ble_output.PAI
                Battery_voltage.value = ble_output.battery_voltage
                Counter.value   = ble_output.counter
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
