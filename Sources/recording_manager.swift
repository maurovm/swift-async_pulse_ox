/**
 * \file    recording_manager.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 9, 2022
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
 * Main class that handles/coordinates the recording process
 * for a Nonin pulseoximeter
 */
@MainActor
public final class Recording_manager : Device_manager
{
    
    private(set) var vital_signs_display_model : Vital_sign_numerics_model
    
    
    /**
     * Class initialiser
     */
    public init(
            orientation  : UIDeviceOrientation,
            preview_mode : Device.Content_mode,
            device_state : Device.Recording_state,
            connection_timeout : Double
        )
    {
        
        let device_id =  settings.peripheral_name ?? "Unknown BLE device"
        
        pulse_oximeter = Pulse_oximeter(device_id)
        
        self.vital_signs_display_model = Vital_sign_numerics_model()
        
        super.init(
                identifier   : device_id,
                sensor_type  : .pulse_oximeter,
                settings     : self.settings,
                orientation  : orientation,
                preview_mode : preview_mode,
                device_state : device_state,
                connection_timeout: connection_timeout
            )
        
    }
    
    
    convenience init(
            orientation  : UIDeviceOrientation,
            preview_mode : Device.Content_mode,
            device_state : Device.Recording_state,
            connection_timeout        : Double,
            vital_signs_display_model : Vital_sign_numerics_model? = nil
        )
    {
        
        self.init(
                orientation  : orientation,
                preview_mode : preview_mode,
                device_state : device_state,
                connection_timeout: connection_timeout
            )
        
        if let display_model = vital_signs_display_model
        {
            self.vital_signs_display_model = display_model
        }
        else
        {
            self.vital_signs_display_model = Vital_sign_numerics_model()
        }
        
    }
    
    
    // MARK: - Device manager life cycle management methods
    
    
    public override func device_check_access() async throws
    {
        
        try await pulse_oximeter.is_bluetooth_powered_on()
        
    }

    
    public override func device_connect(recording_path: URL) async throws
    {
                
        
        try validate_services_and_characteristics(settings.characteristics)
        
        
        await pulse_oximeter.$central_manager_event
            .receive(on: RunLoop.main)
            .sink
            {
                [weak self] event in
                self?.central_manager_event(event)
            }
            .store(in: &bluetooth_event_subscriptions)
        
        
        await pulse_oximeter.$peripheral_event
            .receive(on: RunLoop.main)
            .sink
            {
                [weak self] event in
                self?.pulse_oximeter_event(event)
            }
            .store(in: &bluetooth_event_subscriptions)
        
        
        // load peripheral_id from settings
        
        guard let peripheral_id = settings.peripheral_id
            else
            {
                throw Device.Connect_error.unsupported_configuration(
                        device_id   : identifier,
                        description : "No BLE peripherals configured"
                    )
            }
        
        
        try await pulse_oximeter.connect(peripheral_id)
        
        // Set the device manager as connected here, so we can later
        // gracefully disconnect from the BLE peripheral as part of the
        // normal Device Manager's life cycle management
        
        set_device_connected()
        
        
        let service_UUIDs = Array(settings.characteristics.keys)
        try await pulse_oximeter.discover_services(service_UUIDs)
        
        
        for (service_UUID, characteristic_UUIDs) in settings.characteristics
        {
            try await pulse_oximeter.discover_characteristics(
                    characteristic_UUIDs, for: service_UUID
                )
        }
        
        
        try await initialise_all_data_writers(recording_path)
        
    }
    
    
    public override func device_start_recording() async throws
    {
        
        do
        {
            try await start_data_writers()
        }
        catch let error as Device.Start_recording_error
        {
            throw error
        }
        catch
        {
            throw  Device.Start_recording_error.failed_to_start(
                    device_id   : identifier,
                    description : "Unhandled error while " +
                                  "starting to data writers: " +
                                  error.localizedDescription
                )
        }
        
    }
    
    
    public override func device_stop_recording() async throws
    {
        
        try await stop_data_writers()
        
    }
    
    
    public override func device_disconnect() async throws
    {
        
        all_data_writers.removeAll()
        
        remove_all_display_subscriptions()
        remove_all_bluetooth_subscriptions()
        vital_signs_display_model.remove_all_signals()
        
        try await pulse_oximeter.disconnect()
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * The recording settings for the camera
     */
    private let settings = Recording_settings()
    
    private let pulse_oximeter   : Pulse_oximeter
    
    private var all_data_writers : [CBCharacteristic.Label_type : BLE_notifications_writer ] = [:]
    
    private var vital_signs_display_subscriptions = Set<AnyCancellable>()
    
    private var bluetooth_event_subscriptions     = Set<AnyCancellable>()
    
    
    // MARK: - Private interface
    
    
    private func validate_services_and_characteristics(
            _  uuid_map : [CBService.ID_type : [CBCharacteristic.ID_type]]
        ) throws
    {
        
        let result = AS_pulse_ox.is_recording_supported(for_UUIDs: uuid_map)
        
        do
        {
            try result.get()
        }
        catch Pulse_ox_error.empty_configuration
        {
            throw Device.Connect_error.empty_configuration(
                    device_id  : identifier
                )
        }
        catch Pulse_ox_error.services_not_supported(let services)
        {
            throw Device.Connect_error.recording_not_supported(
                    device_id   : identifier,
                    description : "Recording not supported from services: " +
                                 services
                )
        }
        catch Pulse_ox_error.characteristics_not_supported(let characteristics)
        {
            throw Device.Connect_error.recording_not_supported(
                    device_id   : identifier,
                    description : "Recording not supported from " +
                                  " characteristics: " + characteristics
                )
        }
        catch Pulse_ox_error.no_characteristics_configured(let services)
        {
            throw Device.Connect_error.unsupported_configuration(
                    device_id   : identifier,
                    description : "No characteristics configured for " +
                                  " services: '\(services)'"
                )
        }
        catch
        {
            throw Device.Connect_error.unsupported_configuration(
                    device_id   : identifier,
                    description : "Error validating the configured " +
                                  "BLE characteristics"  +
                                  error.localizedDescription
                )
        }
        
    }
    
    
    // MARK: - Methods to configure data writers
    
    
    private func initialise_all_data_writers( _ recording_path: URL ) async throws
    {
        
        // Reset UI components
        
        all_data_writers.removeAll()
        remove_all_display_subscriptions()
        vital_signs_display_model.remove_all_signals()
        
        
        // Determine which characteristic we will going to display data
      
        let labels_to_display = await get_signal_labels_to_display()
        
        // create all the data writers
        
        let characteristics_labels = await pulse_oximeter.get_configured_characteristics_labels()
        
        for label in characteristics_labels
        {
            let display_flag = labels_to_display.contains(label)
            
            all_data_writers[label] = try await create_data_writer(
                    for_label         : label,
                    recording_enabled : settings.recording_enabled,
                    recording_path    : recording_path,
                    display_flag      : display_flag
                )
            
        }
        
        if all_data_writers.isEmpty
        {
            throw Device.Connect_error.unsupported_configuration(
                    device_id : identifier ,
                    description: "No supported BLE data writers available"
                )
        }
        
    }
    
    
    private func get_signal_labels_to_display() async -> [CBCharacteristic.Label_type]
    {
        
        // TODO: Put this in the application settings
        
        let default_labels_to_display : [CBCharacteristic.Label_type] =
            [ .nonin_continuous_oximetry , .nonin_device_status ]
        
        let configured_labels = await pulse_oximeter.get_configured_characteristics_labels()
        
        var labels_to_display : [CBCharacteristic.Label_type] = []
     
        // Check if the default labels were chosen by the user
        
        for label in default_labels_to_display
        {
            if configured_labels.contains(label)
            {
                labels_to_display.append(label)
            }
        }
        
        // If none of the default signal labels were chosen by the user,
        // check if any of the supported labels are
        
        if labels_to_display.isEmpty
        {
            for label in AS_pulse_ox.supported_characteristics
            {
                if configured_labels.contains(label)
                {
                    labels_to_display.append(label)
                    break;
                }
            }
        }
        
        return labels_to_display
        
    }
    

    private func create_data_writer(
            for_label  label             : CBCharacteristic.Label_type,
                       recording_enabled : Bool,
                       recording_path    : URL,
                       display_flag      : Bool
        )  async throws -> BLE_notifications_writer
    {
        
        // Choose the decoder for the characterisitc requested
        
        let decoder : BLE_decoder
        
        switch label
        {
            case .nonin_continuous_oximetry:
                decoder = BLE_NCO_spec_decoder()
                
            case .nonin_PPG:
                decoder = BLE_NPPG_spec_decoder()
                
            case .nonin_pulse_interval_time:
                decoder = BLE_NPIT_spec_decoder()
                
            case .nonin_device_status:
                decoder = BLE_NDS_spec_decoder()
                
            case .battery_level:
                decoder = BLE_BAS_spec_decoder()
                
            default:
                throw Device.Connect_error.unsupported_configuration(
                        device_id : identifier ,
                        description: "Could not find decoder for " +
                                     "characteristic \(label.description)"
                    )
        }
        
        
        // Create the BLE writer and connect the output data publishers
                        
        let writer = BLE_notifications_writer(
                device_identifier  : identifier,
                BLE_service        : pulse_oximeter,
                decoder            : decoder,
                recording_enabled  : recording_enabled,
                recording_path     : recording_path,
                publishing_enabled : display_flag
            )
        
        try await writer.configure()
        
        if display_flag
        {
            await configure_data_writer_display(writer, decoder)
        }
        
        return writer
        
    }
    
    
    private func configure_data_writer_display(
            _  writer  : BLE_notifications_writer,
            _  decoder : BLE_decoder
        )  async
    {
        
        switch decoder.label
        {
                
            case .nonin_device_status:

                await writer.$output.receive(on: RunLoop.main)
                    .sink
                    {
                        [weak self] output in
                        self?.vital_signs_display_model.new_battery_percentage(output)
                    }
                    .store(in: &vital_signs_display_subscriptions)
                
            default:
                
                let signals = decoder.get_minimum_numerics()
                vital_signs_display_model.add_vital_signs(signals)
                
                await writer.$output.receive(on: RunLoop.main)
                    .sink
                    {
                        [weak self] output in
                        self?.vital_signs_display_model.new_signal_value(output)
                    }
                    .store(in: &vital_signs_display_subscriptions)
        }

    }

    
    private func start_data_writers() async throws
    {
        
        let device_id = identifier
        
        let number_of_started_writer = try await withThrowingTaskGroup(
                of        : Bool.self,
                returning : Int.self
            )
        {
            task_group -> Int in
                        
            for writer in all_data_writers.values
            {
                let writer_label = await writer.label
                
                let task_added = task_group.addTaskUnlessCancelled()
                {
                    var is_started = false
                    
                    do
                    {
                        try await writer.start()
                        is_started = true
                    }
                    catch let error as Device.Start_recording_error
                    {
                        throw error
                    }
                    catch
                    {
                        throw  Device.Start_recording_error.failed_to_start(
                                device_id   : device_id,
                                description : "Unhandled error while " +
                                          "starting data writer " +
                                          "'\(writer_label.description)': " +
                                          error.localizedDescription
                            )
                    }
                    
                    return is_started
                }
                
                if task_added == false
                {
                    break
                }
            }
            
            var started_writers_count = 0

            for try await writer_started in task_group
            {
                started_writers_count += ( writer_started ? 1 : 0 )
            }
            
            return started_writers_count
        }
        
        
        if (number_of_started_writer != all_data_writers.values.count)
        {
            throw Device.Start_recording_error.failed_to_start_from_all_devices
        }
        
    }
    

    private func stop_data_writers() async throws
    {
        
        var stop_error : Device.Stop_recording_error? = nil
        
        for writer in all_data_writers.values
        {
            let writer_label = await writer.label
            
            do
            {
                try await writer.stop()
            }
            catch let error as Device.Stop_recording_error
            {
                stop_error = error
            }
            catch
            {
                stop_error = Device.Stop_recording_error.failed_to_stop(
                        device_id   : identifier,
                        description : "Unhandled error while " +
                                      "stopping data writer " +
                                      "'\(writer_label.description)': "  +
                                      error.localizedDescription
                    )
            }
        }
        
        
        if let error = stop_error
        {
            throw error
        }
        
    }
    
    
    // MARK: - Utility methods
    
    
    private func remove_all_display_subscriptions()
    {
        
        for subscription in vital_signs_display_subscriptions
        {
            subscription.cancel()
        }
        
        vital_signs_display_subscriptions.removeAll()
        
    }
    
    
    private func remove_all_bluetooth_subscriptions()
    {
        
        for subscription in bluetooth_event_subscriptions
        {
            subscription.cancel()
        }
        
        bluetooth_event_subscriptions.removeAll()
        
    }
    
    
    // MARK: - BLE events
    
    
    private func central_manager_event( _  event : ASB_central_manager_event )
    {
        
        switch event
        {
                
            case .peripheral_disconnected(
                        let peripheral_id,
                        let name,
                        let error
                    ):
                
                manager_event = .device_disconnected(
                    device_id   : identifier,
                    description : "Disconnected from peripheral ( " +
                                "name = '\(name)' , " +
                                "id = '\(peripheral_id)') with error : " +
                                "\(error?.localizedDescription ?? "no error")"
                )
                
            
            case .no_continuation_for_did_connect(
                        let peripheral_id,
                        let error
                    ):
            
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
                
                print(
                    "The peripheral \(peripheral_id) has been disconnected " +
                    "without a continuation: \(message)"
                    )
                
            
            case .no_continuation_for_did_failt_to_connect(
                        let peripheral_id,
                        let error
                    ):
                
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
            
                print(
                    "Failed to connect to peripheral \(peripheral_id), " +
                    "no continuation : \(message)"
                    )
                
            
            case .no_continuation_for_did_disconnect(
                        let peripheral_id,
                        let error
                    ):
                
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
            
                print(
                    "No continuation when disconnecting from peripheral " +
                    "\(peripheral_id), error : \(message)"
                    )
                
                
            default:
                break
                
        }
        
    }
    
    private func pulse_oximeter_event( _ event : ASB_peripheral_event )
    {
        
        switch event
        {
                
            case .different_delegate_class(
                        let peripheral_id,
                        let class_name
                    ):
                
                print(
                    "ERROR!: Peripheral '\(peripheral_id)' has a delegate " +
                    "of differnet class: \(class_name)"
                )
                
                
        
            case .no_continuation_for_service_discovery(
                        let peripheral_id,
                        let error
                    ):
                
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
            
                print(
                    "No continuation when discovering services for peripheral " +
                    "'\(peripheral_id)', error : \(message)"
                    )
                
                
            case .no_continuation_for_included_service_discovery(
                        let peripheral_id,
                        let error
                    ):
                
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
            
                print(
                    "No continuation when discovering for included services " +
                    "for peripheral '\(peripheral_id)', error : \(message)"
                    )
                
                
            case .no_continuation_for_characteristic_discovery(
                        let peripheral_id,
                        let service_id,
                        let error
                    ):
                
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
            
                print(
                    "No continuation when discovering characterisitcs for " +
                    "service '\(service_id)', peripheral '\(peripheral_id)', " +
                    "error : \(message)"
                    )
                
                
            case .no_continuation_for_descriptor_discovery(
                        let peripheral_id,
                        let characteristic_id,
                        let error
                    ):
                
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
            
                print(
                    "No continuation when discovering descriptors for " +
                    "characteristic '\(characteristic_id)' , " +
                    "peripheral '\(peripheral_id)' , error : \(message)"
                    )
                
                
            case .no_continuation_for_RSSI_reader(
                        let peripheral_id,
                        let error
                    ):
                
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
            
                print(
                    "No continuation for RSSI reader for " +
                    "peripheral '\(peripheral_id)' , error : \(message)"
                    )
                
                
            case .no_continuation_for_L2CAP_channel(
                        let peripheral_id,
                        let error
                    ):
            
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
                
                print(
                    "No continuation when oppening an L2CAP channel for " +
                    "peripheral \(peripheral_id) , error : \(message)"
                    )
                
                
                
            case .failed_to_read_characteristic_value(
                    let peripheral_id,
                    let characteristic_id,
                    let error
                ):
            
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
                
        
                print(
                    "Cannot read value for characteristic '\(characteristic_id)' " +
                    "Peripheral '\(peripheral_id)'. Error: '\(message)'"
                    )
                
                
            case .failed_to_read_descriptor_value(
                    let peripheral_id,
                    let descriptor_id,
                    let error
                ):
            
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
                
        
                print(
                    "Cannot read value for descriptor '\(descriptor_id)' " +
                    "Peripheral '\(peripheral_id)'. Error: '\(message)'"
                    )
                
                
                
            case .failed_to_write_characteristic_value(
                    let peripheral_id,
                    let characteristic_id,
                    let error
                ):
            
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
                
        
                print(
                    "Cannot write value for characteristic " +
                    "'\(characteristic_id)', peripheral '\(peripheral_id)', " +
                    "Error: '\(message)'"
                    )
                
                
            case .failed_to_write_descriptor_value(
                    let peripheral_id,
                    let descriptor_id,
                    let error
                ):
            
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
                
        
                print(
                    "Cannot write value for descriptor '\(descriptor_id)' " +
                    "Peripheral '\(peripheral_id)'. Error: '\(message)'"
                    )
                
                
                
            case .failed_to_set_notify_value(
                    let peripheral_id,
                    let characteristic_id,
                    let error
                ):
            
                let message : String
                
                if let exec_error = error as? Executor_error
                {
                    message = exec_error.description
                }
                else
                {
                    message = error.localizedDescription
                }
                
        
                print(
                    "Cannot set notify value for characteristic " +
                    "'\(characteristic_id)', peripheral '\(peripheral_id)', " +
                    "Error: '\(message)'"
                    )
                
                
            default:
                break
                
        }
        
    }
    
}
