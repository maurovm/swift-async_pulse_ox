/**
 * \file    vital_sign_numerics_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 1, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import SensorRecordingUtils


struct Vital_sign_numerics_view : View
{
    
    var body: some View
    {
        GeometryReader
        {
            geo in
        
            ScrollView(.horizontal)
            {
                HStack(alignment: .center, spacing: 10)
                {
                    ForEach(model.vital_signs)
                    {
                        vital_sign in

                        BLE_signal_view(
                                id        : vital_sign.id,
                                name      : vital_sign.name,
                                units     : vital_sign.units,
                                gain      : vital_sign.gain,
                                value     : vital_sign.value
                            )
                        .frame(width: 70)
                        .padding(.vertical, 5)
                    }
                }
                .frame(
                    width    : geo.size.width,
                    height   : geo.size.height,
                    alignment: .center
                )
            }
            
        }
    }


    public init( _  model  : Vital_sign_numerics_model )
    {
        
        _model = ObservedObject(wrappedValue: model)
        
    }


    // MARK: - Private state


    @ObservedObject  private var model: Vital_sign_numerics_model

}



struct BLE_notifications_reader_view_Previews: PreviewProvider
{

    static let decoder = BLE_NCO_spec_decoder()
    
    
    static var previews: some View
    {
        Group
        {
            Vital_sign_numerics_view(
                Vital_sign_numerics_model( decoder.get_minimum_numerics() )
                )
                .background(.cyan)
                .previewInterfaceOrientation(.landscapeRight)
                .previewLayout(.fixed(width: 600, height: 90))
        }
    }

}
