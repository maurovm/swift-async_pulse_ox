/**
 * \file    ble_npit_spec_notifications_model.swift
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
import Combine
import AsyncBluetooth
import SensorRecordingUtils


/**
 * Data model for the notification data from the Characteritic:
 *
 * "34E27863-76FF-4F8E-96F1-9E3993AA6199" : "Nonin Pulse Interval Time"
 */
@MainActor
class BLE_NPIT_spec_notifications_model : ObservableObject
{
    
    
    // MARK: - Data to diplay
    
    
    @Published private(set) var status  = BLE_NPIT_spec_decoder.Status(rawValue: 0)
    
    @Published private(set) var Counter : BLE_signal
    
    /**
     * It will hold one HR and multiple RR_intervals
     */
    @Published private(set) var all_pulses : [NPIT_pulse_signal] = []
    
    @Published public var show_decode_alert = false
    
    private(set) var decode_error: ASB_error?
    
    
    /**
     * Class initialiser
     */
    init(
        _  data_publisher : Published<ASB_data>.Publisher,
           pulses         : [NPIT_pulse_signal]        = []
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
        
        if pulses.isEmpty == false
        {
            all_pulses = pulses
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
    private var decoder           = BLE_NPIT_spec_decoder()
    
    // MARK: - Private interface
    
    
    private func decode( _ data: ASB_data )
    {
        
        do
        {
            if let ble_output = try decoder.decode(data) as? BLE_NPIT_spec_decoder.Output
            {
                status        = ble_output.status
                Counter.value = ble_output.counter
                
                // Decode each NPIT pulse
                
                let values = ble_output.pulses
                
                // show the values for the views that already exist
                let limit = min(values.count, all_pulses.count)
                
                for i in 0..<limit
                {
                    all_pulses[i].bad_pulse_flag   = values[i].bad_pulse_flag
                    all_pulses[i].PAI.value        = values[i].PAI
                    all_pulses[i].pulse_time.value = values[i].pulse_time
                }
                
                if values.count > all_pulses.count
                {
                    // Create new views because there is more data than views
                    
                    for i in limit..<values.count
                    {
                        guard let signal = decoder.get_signal(.PAI)
                            else
                            {
                                throw ASB_error.decode_data(
                                    description: "Cannot decode PAI signal"
                                )
                            }
                        
                        var new_PAI = signal
                        new_PAI.value = values[i].PAI
                        
                        guard let signal = decoder.get_signal(.pulse_time)
                            else
                            {
                                throw ASB_error.decode_data(
                                    description: "Cannot decode pulse_time signal"
                                )
                            }
                        
                        var new_pulse_time = signal
                        new_pulse_time.value = values[i].pulse_time
                        
                        all_pulses.append( NPIT_pulse_signal(
                            bad_pulse_flag: values[i].bad_pulse_flag,
                            PAI           : new_PAI,
                            pulse_time    : new_pulse_time
                        ))
                    }
                }
                else if values.count < all_pulses.count
                {
                    // Delete views if there are less data received than views
                    
                    let range = limit..<all_pulses.count
                    all_pulses.removeSubrange(range)
                }
            }
            
        }
        catch let error as ASB_error
        {
            decode_error = error
            show_decode_alert = true
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
