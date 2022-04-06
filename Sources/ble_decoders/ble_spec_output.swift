/**
 * \file    ble_spec_output.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 3, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation


/**
 * The decoded values from the raw data sent by a BLE characteristic
 */
protocol BLE_spec_Output
{
    
    /**
     * Returns:  an array because other decoders return multiple signal
     *        values (i.e. the PPG)
     */
    func csv_value() -> String
    
    /**
     * returns the raw integer value for the given signal type
     */
    func value(
            _ signal_label : BLE_signal_type
        ) -> Int?
        
}
