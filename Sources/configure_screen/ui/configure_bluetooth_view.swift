/**
 * \file    configure_bluetooth_view.swift
 * \author  Mauricio Villarroel
 * \date    Created: Jan 24, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import SwiftUI
import CoreBluetooth
import AsyncBluetooth
import SensorRecordingUtils


/**
 * View to select to which Nonin device to connect
 */
public struct Configure_bluetooth_view: View
{
    
    public var body: some View
    {
        
        GeometryReader
        {
            geo in
            
            
            // Grid layout configuration
            
            let size_divider = CGFloat(number_of_panels)
            
            let panel_width  = is_landscape ? (geo.size.width / size_divider) : geo.size.width
            
            let panel_height = is_landscape ? geo.size.height : (geo.size.height / size_divider)
                        
            let grid_layout = Array(
                repeating : GridItem(.fixed(panel_width), spacing: 0, alignment: .center),
                count     : is_landscape ? number_of_panels : 1
                )
            
            
            // The actual grid
            
            
            LazyVGrid(columns: grid_layout, alignment: .center, spacing: 0)
            {
                
                Left_panel_view
                    .frame(
                        width     : panel_width,
                        height    : panel_height,
                        alignment : .center
                    )
                
                //Divider()
                
                Right_panel_view
                    .frame(
                        width     : panel_width,
                        height    : panel_height,
                        alignment : .center
                    )
                
            }
            
        }
        .task
        {
            if scan_on_startup
            {
                if await model.start_scanning() == false
                {
                    show_setup_alert = true
                }
            }
        }
        .toolbar
        {
            ToolbarItem(placement: .navigationBarLeading)
            {
                Button( "Cancel", role: .cancel, action: close_window )
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .controlSize(.small)
            }

            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button("Clear", role: .destructive)
                {
                    model.clear_all_selections()
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .controlSize(.small)
            }

            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button("Save", action: save_settings_if_not_empty)
                .tint(.cyan)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle)
                .controlSize(.small)
                .confirmationDialog(
                        Text(
                            "No characteristics have been selected, all existing settings will be deleted. Exit anyway?"
                            ),
                        isPresented     : $selection_is_empty_warning,
                        titleVisibility : .visible
                    )
                    {
                        Button("Yes", role: .destructive)
                        {
                            model.save_settings()
                            close_window()
                        }
                        Button("NO", role: .cancel , action: {})
                    }
                .confirmationDialog(
                        Text(
                            "Recording is not supported for \n'\(model.recording_support_error)'\n or it does not have any characteristics configured. Please clear selection or choose other characteristics"
                            ),
                        isPresented     : $recording_not_supported_warning,
                        titleVisibility : .visible
                    )
                    {
                        Button("Clear selection", role: .destructive)
                        {
                            model.clear_all_selections()
                        }
                        Button("Change selection", role: .cancel , action: {})
                    }
                
            }
        }
        .alert("Error",
               isPresented : $show_setup_alert,
               presenting  : model.setup_error,
               actions:
                {
                    error_type in

                    switch error_type
                    {
                        case .bluetoothUnavailable:
                            Button("Open settings", action: open_application_settings)
                            Button("Dismiss",  action: {})
                        
                        default:
                            Button("Dismiss",  action: {})
                    }
                    
                },
               message:
                {
                    error_type in
            
                    Text( setup_error_message(error_type) )
                }
            )
        .navigationBarTitle("Select characteristics")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(false)
        
    }

    
    /**
     * Class initialiser
     */
    public init(  scan_on_startup : Bool = true  )
    {
        
        self.scan_on_startup = scan_on_startup
        self._model = StateObject( wrappedValue: Configure_bluetooth_model() )
        
    }
    
    
    // MARK: - Private body Views
    
    
    private var Left_panel_view: some View
    {
        
        List
        {
            Section
            {
                ForEach(all_filtered_peripherals)
                {
                    Peripheral_list_row_view($0)
                }
                
            }
            header :
            {
                HStack
                {
                    Text("Peripherals: \(all_filtered_peripherals.count)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("Filter : ")
                        .font(.caption)
                        .frame(width: 50)
                    
                    TextField("By name",
                              text: $model.peripheral_name_filter
                        )
                    .disableAutocorrection(true)
                    .keyboardType(.alphabet)
                    .lineLimit(1)
                    .textInputAutocapitalization(.characters)
                    .textContentType(.username)
                    .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                    
                }
            }
            
            Section
            {
                ForEach(model.all_services)
                {
                    Service_list_row_view($0)
                }
                
            }
            header :
            {
                HStack
                {
                    Text("Services: \(model.all_services.count)")
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .listStyle(.insetGrouped)
        
    }
    

    
    @ViewBuilder
    private func Peripheral_list_row_view(
            _  peripheral : ASB_peripheral
        ) -> some View
    {
        
        HStack
        {
            // The button to select the peripheral

            Selectable_check_button(
                    is_selected: model.is_peripheral_selected(peripheral.id)
                )

            // The button to connect to the peripheral

            Toggle_button(
                    text           : peripheral.name,
                    id             : peripheral.id,
                    active_id      : model.active_peripheral?.id,
                    is_processing  : (model.disconnecting_to_peripheral || model.connecting_to_peripheral || model.searching_for_services),
                    processing_text: peripheral_processing_message
                )
            {
                Task
                {
                    if await model.connect_to_peripheral(peripheral.id) == false
                    {
                        show_setup_alert = true
                    }
                }
            }

        }
    }

    
    @ViewBuilder
    private func Service_list_row_view(
            _  service : CBService
        ) -> some View
    {
        HStack
        {

            // The button to select the service

            Selectable_check_button(
                    is_selected: model.is_service_selected(service.uuid)
                )

            // The button to discover characteristics for the service

            Toggle_button(
                    text           : service.name,
                    id             : service.uuid,
                    active_id      : model.active_service?.uuid,
                    is_processing  : model.searching_for_characteristics,
                    processing_text: "Discovering characteristics ..."
                )
            {
                Task
                {
                    if await model.discover_characteristics(for: service) == false
                    {
                        show_setup_alert = true
                    }
                }
            }

        }
    }

    
    private var Right_panel_view: some View
    {
        
        List
        {
            Section
            {
                ForEach(model.all_characteristics)
                {
                    Characteristic_list_row_view($0)
                }
                
            }
            header :
            {
                Characteristics_header_view
            }
        }
        .listStyle(.insetGrouped)
        
    }

    
    private var Characteristics_header_view: some View
    {
        HStack
        {
            Text("Characteristics: \(model.all_characteristics.count)")
                .font(.subheadline)

            Spacer()
            
            // Link to the Service detail page
            
            if let peripheral     = model.active_peripheral ,
               let characteristic = model.active_characteristic
            {
                NavigationLink(
                        destination: Characteristic_detail_view(
                            peripheral        : peripheral,
                            cb_characteristic : characteristic
                        ),
                        isActive: $characteristic_details_enabled
                    )
                {
                    Button("Detail")
                    {
                        characteristic_details_enabled = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    
    @ViewBuilder
    private func Characteristic_list_row_view(
            _  characteristic : CBCharacteristic
        ) -> some View
    {
        HStack
        {

            // The button to select the characteristic

            Selectable_check_button(
                is_selected: model.is_characteristic_selected(characteristic.uuid),
                enabled    : true
                )
            {
                model.toggle_selection_for_characteristic(characteristic.uuid)
            }

            // The button to discover descriptors for the characteristic

            Toggle_button(
                    text           : characteristic.name,
                    id             : characteristic.uuid,
                    active_id      : model.active_characteristic?.uuid,
                    is_processing  : model.searching_for_descriptors,
                    processing_text: "Discovering descriptors ..."
                )
            {
                Task
                {
                    if await model.discover_descriptors(for: characteristic) == false
                    {
                        show_setup_alert = true
                    }
                }
            }

        }
    }


    // MARK: - Private Actions


    /**
     * Open iOS settings app
     */
    private func open_application_settings()
    {
        if let url = URL(string: UIApplication.openSettingsURLString)
        {
            UIApplication.shared.open(url)
            {
                status in
                print("settings app called, result: \(status)")
            }
        }
    }
    
    
    private func save_settings_if_not_empty()
    {
        
        if model.is_selection_empty()
        {
            selection_is_empty_warning = true
        }
        else if model.is_recording_supported() == false
        {
            recording_not_supported_warning = true
        }
        else
        {
            model.save_settings()
            close_window()
        }
        
    }
    
    
    private func close_window()
    {
        
        Task
        {
            if await model.disconnect_from_active_peripheral()
            {
                model.save_peripheral_name_filter()
                dismiss()
            }
            else
            {
                show_setup_alert = true
            }
            
        }
        
    }
    
    
    // MARK: - Private state
    
    
    @StateObject private var model : Configure_bluetooth_model
    
    /**
     * Wether or not to scan for bluetooth peripherals as soon as
     * this View is created.
     *
     * This is done, so the SwiftUI Preview is manageable
     */
    private let scan_on_startup : Bool

    private let number_of_panels = 2
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var characteristic_details_enabled  : Bool = false
    @State private var selection_is_empty_warning      : Bool = false
    @State private var recording_not_supported_warning : Bool = false
    
    @State private var show_setup_alert = false
    
    @Environment(\.horizontalSizeClass) private var horizontal_size
    
        
    private var all_filtered_peripherals : [ASB_peripheral]
    {
        let filter_string = model.peripheral_name_filter.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        
        if filter_string.isEmpty
        {
            return model.all_peripherals
        }
        else
        {
            return model.all_peripherals.filter
            {
                $0.name.range(
                    of      : filter_string,
                    options : .caseInsensitive
                ) != nil
            }
        }
    }
    
    
    /**
     * Message to display when connecting or loading services from a
     * peripheral
     */
    private var peripheral_processing_message : String
    {
        if model.disconnecting_to_peripheral
        {
            return "Disconnecting to peripheral ..."
        }
        else if model.connecting_to_peripheral
        {
            return "Connecting to peripheral ..."
        }
        else if model.searching_for_services
        {
            return "Loading services ..."
        }
        else
        {
            return  "Other message"
        }
    }
    
    
    private var is_landscape : Bool
    {
        horizontal_size == .regular
    }
    
    
    private func setup_error_message(
            _  error_type : ASB_error
        ) -> String
    {
        
        switch error_type
        {
            case .bluetoothUnavailable:
                
                return "The App requires access to Bluetooth devices"

                
            case .scanning_in_progress:
                
                return "Already scanning for peripherals"
                
            case .failed_to_scan_for_peripherals(let message):
                
                return "Can't scan for peripherals: \(message)"

                
            case .failed_to_connect_to_peripheral(let error):
            
                let message = error?.localizedDescription ?? "-"
                return "Can't connect to Peripheral: \(message)"
                
            case .no_connection_to_peripheral_exists:
                
                return "Unable to cancel connection: no connection to peripheral exists nor being attempted"
                
            case .disconnecting_in_progress:
                
                return "Unable to disconnect from peripheral because a disconnection attempt is already in progress"

                

            case .failed_to_discover_service(let error):
                
                return "Failed to discover services for peripheral: " +
                       "\(error.localizedDescription)"
                

            case .failed_to_discover_characteristics(let error):
                
                return "Failed to discover characteristic for service: " +
                       "\(error.localizedDescription)"

                

            case .failed_to_discover_descriptor(let error):
                
                return "Failed to discover descriptor for characteristic: " +
                       "\(error.localizedDescription)"


                
            case .unknown_error(let message):
                
                return message
                
            default:
                
                return "Unknown error"
        }
            
    }
    
}



struct Bluetooth_devices_view_Previews: PreviewProvider
{
    
    static var previews: some View
    {
        
        
        NavigationView
        {
            Configure_bluetooth_view( scan_on_startup: false )
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.landscapeRight)
        
        
        
        NavigationView
        {
            Configure_bluetooth_view( scan_on_startup: false )
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.portrait)
        
    }
}
