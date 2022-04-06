/**
 * \file    ble_hrs_spec_notifications_model.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 8, 2022
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
 *   2A37 : "Hearr Rate Measurement"
 */
@MainActor
class BLE_HRS_spec_notifications_model : ObservableObject
{
    
    /**
     * It will hold one HR and multiple RR_intervals
     */
    @Published private(set) var all_vital_signs : [BLE_signal] = []
    
    
    @Published public var show_decode_alert = false
    
    private(set) var decode_error: ASB_error?
    

    init(
        _  data_publisher :  Published<ASB_data>.Publisher,
           vital_signs    : [BLE_signal]              = []
        )
    {
        
        if vital_signs.isEmpty == false
        {
            all_vital_signs = vital_signs
        }
        else
        {
            if let signal = decoder.get_signal(.HR)
            {
                all_vital_signs.append(signal)
            }
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
    private let decoder           = BLE_HRS_spec_decoder()
    
    
    // MARK: - Private interface
    
    
    private func decode( _ data: ASB_data )
    {
        
        do
        {
            
            if let decoded = try decoder.decode(data) as? BLE_HRS_spec_decoder.Output
            {
                let values = [decoded.HR] + decoded.RR_interval
                
                // show the values for the views that already exist
                let limit = min(values.count, all_vital_signs.count)
                
                for i in 0..<limit
                {
                    all_vital_signs[i].value = values[i]
                }
                
                if values.count > all_vital_signs.count
                {
                    // Create new views because there is more data than views
                    
                    for i in limit..<values.count
                    {
                        guard let signal = decoder.get_signal(.RR_interval)
                            else
                            {
                                throw ASB_error.decode_data(
                                    description: "Cannot decode RR_interval signal"
                                )
                            }
                        
                        var new_signal = signal
                        new_signal.value = values[i]
                        all_vital_signs.append(new_signal)
                    }
                }
                else if values.count < all_vital_signs.count
                {
                    // Delete views if there are less data received than views
                    
                    let range = limit..<all_vital_signs.count
                    all_vital_signs.removeSubrange(range)
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
