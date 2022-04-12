/**
 * \file    ble_data_notifications_writer.swift
 * \author  Mauricio Villarroel
 * \date    Created: Mar 5, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation
import CoreBluetooth
import AsyncBluetooth
import SensorRecordingUtils



/**
 * Writes the content of the data from a characterisit to a CSV file
 */
final actor BLE_notifications_writer
{
    
    @Published private(set) var output : BLE_spec_Output
    
    
    // MARK: - Characteristic identifiers
    
    
    /**
     * The unique id of the characteristic this class is configured to
     * read data from
     */
    var id : CBCharacteristic.ID_type
    {
        get async
        {
            decoder.id
        }
    }
    
    
    /**
     * The label of the characteristic this class is configured to
     * read data from
     */
    var label : CBCharacteristic.Label_type
    {
        get async
        {
            decoder.label
        }
    }
    
    
    /**
     * Class initialiser
     */
    init(
            device_identifier  : Device.ID_type ,
            BLE_service        : Pulse_oximeter,
            decoder            : BLE_decoder,
            recording_enabled  : Bool,
            recording_path     : URL,
            publishing_enabled : Bool = false
        )
    {
        
        self.device_identifier = device_identifier
        self.ble_service       = BLE_service
        
        self.recording_enabled = recording_enabled
        self.recording_path    = recording_path
        self.base_filename     = "ble_spec-\(decoder.label.rawValue)"
        
        self.decoder = decoder
        self.output  = decoder.output_empty_value()
        
        self.publishing_enabled = publishing_enabled
        
    }
    
    
    deinit
    {
        output_file_handle = nil
    }
    
    
    // MARK: - Public interface
    
    
    func configure() async throws
    {
        
        if recording_enabled
        {
            try write_output_info_description()
            
            if let file_handle = try create_output_file()
            {
                write(file_handle, text: decoder.output_csv_header())
                output_file_handle = file_handle
            }
        }
        
    }
    
    
    func start() async throws
    {
        
        if is_recording
        {
            return
        }
        
        // Clean up previous task if it exists
        
        ble_recording_task?.cancel()
        ble_recording_task = nil
        
        ble_recording_task = Task(priority: .high)
        {
            [weak self] in
            
            await self?.start_recording()
        }
        
        is_recording = true
        
    }
    
    
    func stop() async throws
    {
        
        defer
        {
            // Clean up previous task if it exists
            
            ble_recording_task?.cancel()
            ble_recording_task = nil
        }
        
        
        if is_recording
        {
            do
            {
                try await  ble_service.stop_notifications(for: decoder.id)
                output_file_handle = nil
                is_recording = false
            }
            catch let error as Device.Stop_recording_error
            {
                throw error
            }
            catch
            {
                throw Device.Stop_recording_error.failed_to_stop(
                    device_id  : device_identifier,
                    description: "Couldn't not unsubscrebe to notifications " +
                                 "for characteristic '\(decoder.id)'"
                )
            }
        }
        
    }
    
    
    // MARK: - Private state
    
    
    /**
     * Unique identifier for the device.
     */
    private let device_identifier  : Device.ID_type
    
    private var ble_service        : Pulse_oximeter
    private let recording_enabled  : Bool
    private let recording_path     : URL
    private let base_filename      : String
    private let publishing_enabled : Bool
    
    private let decoder : BLE_decoder
    
    private var ble_recording_task : Task<Void, Never>? = nil
    private var is_recording = false
    
    private var output_file_handle : FileHandle? = nil
    
    
    // MARK: - Private interface
    
    
    private func write_output_info_description() throws
    {
        
        let output_file_path  = recording_path
            .appendingPathComponent("\(base_filename)-info")
            .appendingPathExtension("csv")
        
        let output_info_description = decoder.output_info_description()
        
        do
        {
            try output_info_description.write(
                    to         : output_file_path,
                    atomically : true,
                    encoding   : String.Encoding.utf8
                )
        }
        catch
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                device_id: device_identifier,
                description: "Could not create output info file " +
                             "characteristic '\(decoder.id)' " +
                             "at path '\(output_file_path.path)'"
                )
        }
        
    }
    
    
    private func create_output_file() throws -> FileHandle?
    {
        
        let output_file_path  = recording_path
            .appendingPathComponent(base_filename)
            .appendingPathExtension("csv")
        
        
        var file_handle : FileHandle? = nil
        
        do
        {
            
            if FileManager.default.fileExists(atPath: output_file_path.path)
            {
                throw Device.Connect_error.create_output_folder(
                        device_id    : device_identifier,
                        path         : output_file_path.path,
                        description  : "output file already exists"
                    )
            }
            
            if FileManager.default.createFile(
                    atPath : output_file_path.path, contents : nil
                ) == false
            {
                throw Device.Connect_error.failed_to_connect_to_device(
                    device_id: device_identifier,
                    description: "Failed to create output file for " +
                                 "characteristic '\(decoder.id)' " +
                                 "at path '\(output_file_path.path)'"
                )
            }
            
            file_handle = try FileHandle(forWritingTo: output_file_path)
            
        }
        catch let error as Device.Connect_error
        {
            throw error
        }
        catch
        {
            throw Device.Connect_error.failed_to_connect_to_device(
                device_id: device_identifier,
                description: "Failed to create output file for " +
                             "characteristic '\(decoder.id)' " +
                             "at path '\(output_file_path.path)' " +
                             " - Error: " + error.localizedDescription
            )
            
        }
        
        return file_handle
        
    }
    
    
    // FIXME: Implement handling of errors
    private func start_recording() async
    {
        
        do
        {
            let data_stream = try await ble_service.notification_values(
                    for: decoder.id
                )
            
            if let file_handle = output_file_handle     ,
               (recording_enabled  == true) ,
               (publishing_enabled == true)
            {
                try await write_and_publish(file_handle, stream: data_stream)
            }
            else if let file_handle = output_file_handle     ,
                    (recording_enabled  == true) ,
                    (publishing_enabled == false)
            {
                try await write(file_handle, stream: data_stream)
            }
            else
            {
                try await publish(stream: data_stream)
            }
            
        }
        catch let error as Device.Recording_error
        {
            //throw error
            print("\(Date()) : \(String(describing: Self.self)) : \(#function) : " +
                  "Recording_error = \(error) : " + error.localizedDescription
                )
        }
        catch
        {
            print(
                "\(Date()) : \(String(describing: Self.self)) : \(#function) : " +
                "Couldn't not subscribe to notifications for characteristic " +
                "\(decoder.id) : \(error) : " +
                error.localizedDescription
                )
            
//            throw Device.Recording_error.failed_to_start(
//                device_id  : device_identifier,
//                description: "Couldn't not subscrebe to notifications for " +
//                             "characteristic \(characteristic_id)"
//            )
        }
        
    }
    
    
    // MARK: - Private interface to process the data stream
    
    
    private func write(
            _       file_handle : FileHandle,
            stream  data_stream : AsyncThrowingStream<ASB_data, Error>
        ) async throws
    {
                        
        for try await ble_data in data_stream
        {
            if Task.isCancelled
            {
                break
            }

            if let ble_output = try decoder.decode(ble_data)
            {
                write(file_handle, text: ble_output.csv_value())
            }
        }
        
    }
    
    
    private func write_and_publish(
            _       file_handle : FileHandle,
            stream  data_stream : AsyncThrowingStream<ASB_data, Error>
        ) async throws
    {
                        
        for try await ble_data in data_stream
        {
            if Task.isCancelled
            {
                break
            }

            if let ble_output = try decoder.decode(ble_data)
            {
                write(file_handle, text: ble_output.csv_value())
                output = ble_output
            }
        }
        
    }
    
    
    private func publish(
            stream  data_stream : AsyncThrowingStream<ASB_data, Error>
        ) async throws
    {
                        
        for try await ble_data in data_stream
        {
            if Task.isCancelled
            {
                break
            }

            if let ble_output = try decoder.decode(ble_data)
            {
                output = ble_output
            }
        }
        
    }
    
    
    // MARK: - Function to write to a csv file
    
    
    /**
     * The actual function that writes the data to the output file
     */
    @inline(__always)
    private func write(
            _  file_handle : FileHandle,
               text      : String
        )
    {
        if let data = text.data(using: .utf8)
        {
            file_handle.write(data)
        }
    }
    
}
