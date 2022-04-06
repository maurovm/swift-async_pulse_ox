/**
 * \file    characteristic_detail_model.swift
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
import Combine
import CoreBluetooth
import AsyncBluetooth
import SensorRecordingUtils


/**
 * ViewModel for the view to select to which Nonin device to connect
 */
@MainActor
public final class Characteristic_detail_model : ObservableObject
{
    
    @Published private(set) var value : String = ""
    
    @Published private(set) var is_notifying       : Bool = false
    @Published private(set) var notification_value : ASB_data = ASB_data()
    
    @Published private(set) var notification_update_timestamp = Date()
    
    @Published private(set) var all_properties  : [Characteristic_property] = []
    
    
    struct Characteristic_property : Identifiable
    {
        let id      = UUID()
        let name    : String
        let enabled : Bool
    }

    
    public var name  : String
    {
        characteristic.name
    }
    
    public var label  : CBCharacteristic.Label_type?
    {
        characteristic.label
    }
    
    public var units : String
    {
        return characteristic.label?.description ?? ""
    }
    
    
    /**
     * Class initialiser
     */
    public init(
            peripheral      : ASB_peripheral,
            characteristic  : CBCharacteristic
        )
    {
        
        self.peripheral      = peripheral
        self.characteristic  = characteristic
        
        self.is_notifying = self.characteristic.isNotifying
        
        load_properties()
        
    }
    
    
    /**
     * Clean up resources
     */
    deinit
    {
    }
    
    
    // MARK: - Public interface
    
    
    public func end_session()
    {
        
        Task
        {
            [weak self] in
            await self?.disable_notification()
        }
        
    }
    
    
    /**
     * Verify if the Characteristic has enable the requested property
     */
    func contains(
            property : CBCharacteristicProperties
        ) -> Bool
    {
        
        return characteristic.properties.contains(property)
        
    }
    
    
    public func toggle_notification()
    {
        
        if characteristic.isNotifying
        {
            // Is currently notifying, so stop it
            Task
            {
                await disable_notification()
            }
        }
        else
        {
            // Is not currenlty notifying, so start it
            Task
            {
                await enable_notification()
            }
        }
        
    }
    
    
    public func read_value() async
    {
        
        do
        {
            let ble_data = try await peripheral.read_value(for: characteristic)
            
            if let label = characteristic.label
            {
                switch label
                {
                    case .battery_level:
                        
                        let decoder = BLE_BAS_spec_decoder()
                        
                        if let ble_output = try decoder.decode(ble_data) as? BLE_BAS_spec_decoder.Output
                        {
                            value = "\(String(describing: ble_output.battery_percentage))"
                        }
                        
                    default:
                        value = read_string(from: ble_data.data) ?? "?"
                        
                }
            }
            else
            {
                value = read_string(from: ble_data.data) ?? "?"
            }
        }
        catch
        {
            value = "Can't read characteristic: \(error.localizedDescription)"
        }
        
    }
    
    
    private func read_string(from data : Data) -> String?
    {
        
        return String(data: data, encoding: String.Encoding.utf8)
        
    }
    
    
    // MARK: - Private state
    
    
    private var peripheral     : ASB_peripheral
    private var characteristic : CBCharacteristic
    
    private var notification_subscriber : AnyCancellable? = nil
    
    
    // MARK: - Private interface
    
    
    private func load_properties()
    {
        
        all_properties.append( .init(
            name   : "Broadcast",
            enabled: characteristic.properties.contains(.broadcast)
            ))
        all_properties.append( .init(
            name   : "Read",
            enabled: characteristic.properties.contains(.read)
            ))
        all_properties.append( .init(
            name   : "Write without response",
            enabled: characteristic.properties.contains(.writeWithoutResponse)
            ))
        all_properties.append( .init(
            name   : "Write",
            enabled: characteristic.properties.contains(.write)
            ))
        all_properties.append( .init(
            name   : "Notify",
            enabled: characteristic.properties.contains(.notify)
            ))
        all_properties.append( .init(
            name   : "Indicate",
            enabled: characteristic.properties.contains(.indicate)
            ))
        all_properties.append( .init(
            name   : "Aauthenticated signed writes",
            enabled: characteristic.properties.contains(.authenticatedSignedWrites)
            ))
        all_properties.append( .init(
            name   : "Extended properties",
            enabled: characteristic.properties.contains(.extendedProperties)
            ))
        all_properties.append( .init(
            name   : "Notify encryption required",
            enabled: characteristic.properties.contains(.notifyEncryptionRequired)
            ))
        all_properties.append( .init(
            name   : "Indicate encryption required",
            enabled: characteristic.properties.contains(.indicateEncryptionRequired)
            ))
        
    }
    
    
    private func enable_notification() async
    {
        
        if characteristic.isNotifying
        {
            return
        }
        
        defer
        {
            notification_subscriber?.cancel()
            notification_subscriber = nil
        }
        
        
        do
        {
            is_notifying = true
            
//            switch characteristic.type
//            {
//                case .battery_level:
//                    break
//                case .heart_rate:
//                    break
//
//                default:
//                    notification_subscriber = self.$notification_value.sink
//                    {
//                        [weak self] data in
//
//                        if let data_value = self?.read_string(from: data)
//                        {
//                            self?.value = data_value
//                        }
//                        else
//                        {
//                            self?.value = "?"
//                        }
//                    }
//            }
            
            for try await value in try await peripheral.notification_values(for: characteristic)
            {
                notification_update_timestamp = Date()
                notification_value            = value
            }
            
        }
        catch
        {
            print("Can't subscribe to characteristic: \(error.localizedDescription)")
        }
        
        await disable_notification()
        
    }
    
    
    private func disable_notification() async
    {
        
        if characteristic.isNotifying
        {
            await peripheral.stop_notifications(from: characteristic)
        }
        is_notifying = false
        
    }
    
}
