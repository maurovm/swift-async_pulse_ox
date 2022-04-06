/**
 * \file    ble_bas_spec_notifications_model.swift
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
import Combine
import AsyncBluetooth
import SensorRecordingUtils


/**
 * Data model for the notification data from the Characteritic:
 *
 *   2A19: "Battery Level"
 */
@MainActor
class BLE_BAS_spec_notifications_model : ObservableObject
{
    
    // MARK: - Data to diplay
    
    
    @Published private(set) var Battery_percentage : BLE_signal
    
    @Published public var show_decode_alert = false
    
    private(set) var decode_error: ASB_error?
    
    
    /**
     * Class initialiser
     */
    init( _  data_publisher :  Published<ASB_data>.Publisher )
    {
        
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
    private let decoder           = BLE_BAS_spec_decoder()
    
    
    // MARK: - Private interface
    
    
    private func decode( _ data: ASB_data )
    {
        
        do
        {
            if let decoded = try decoder.decode(data) as? BLE_BAS_spec_decoder.Output
            {
                Battery_percentage.value = decoded.battery_percentage
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
