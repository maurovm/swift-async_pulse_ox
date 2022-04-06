/**
 * \file    ble_nppg_spec_notifications_model.swift
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
import Combine
import AsyncBluetooth
import SensorRecordingUtils


/**
 * Data model for the notification data from the Characteritic:
 *
 *   "EC0A883A-4D24-11E7-B114-B2F933D5FE66":  "Nonin PPG"
 */
@MainActor
class BLE_NPPG_spec_notifications_model : ObservableObject
{
    
    // MARK: - Data to diplay
    
    
    @Published private(set) var Counter    : BLE_signal
    
    @Published public private(set) var values : [Int] = []
    
    /**
     * The offset in the data vector to extract data
     */
    @Published public private(set)  var next_write_index : Int = 0
    
    
    @Published public private(set) var values_min : Int   = -1
    @Published public private(set) var values_max : Int   = 1
    @Published public private(set) var t_min      : Int   = 0
    @Published public private(set) var t_max      : Int   = 1
    
    
    @Published public var show_decode_alert = false
    
    private(set) var decode_error: ASB_error?
    
    
    init(
        _  data_publisher : Published<ASB_data>.Publisher,
           buffer_seconds : Int = 5
        )
    {
        
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
        
        // Initialise PPG buffers
        
        let sample_frequency : Int
        if let signal = decoder.get_signal(.PPG)
        {
            sample_frequency = signal.frequency
            
        }
        else
        {
            sample_frequency = 1
        }
        
        let number_of_samples = buffer_seconds * sample_frequency
        values = [Int](repeating: 0, count: number_of_samples)
        t_max  = buffer_seconds
        
        
        // Listen to new data values from the BLE peripheral
        
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
    private var decoder           = BLE_NPPG_spec_decoder()
    
    
    // MARK: - Private interface
    
    
    private func decode( _ data: ASB_data )
    {
        
        do
        {
            if let decoded = try decoder.decode(data) as? BLE_NPPG_spec_decoder.Output
            {
                Counter.value   = decoded.counter
                
                // Decode PPG data
                
                let new_values = decoded.PPG
                
                if next_write_index >= values.count
                {
                    next_write_index = 0
                }
                
                if (next_write_index + new_values.count) <= values.count
                {
                    for i in 0..<new_values.count
                    {
                        values[next_write_index + i] = new_values[i]
                    }
                    next_write_index += new_values.count
                }
                else
                {
                    let limit = values.count - next_write_index
                    
                    for i in 0..<limit
                    {
                        values[next_write_index + i] = new_values[i]
                    }
                    next_write_index = 0
                    
                    for i in limit..<new_values.count
                    {
                        values[next_write_index + i] = new_values[i]
                    }
                    next_write_index += (new_values.count - limit)
                }
                
                if let y_min = values.min() ,
                   let y_max = values.max()
                {
                    values_min = y_min
                    values_max = y_max
                }
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
