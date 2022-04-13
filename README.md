# AsyncPulseOx

This Swift Package provides the functionality to record time-series data from
devices that support Bluetooth Low Energy (BLE) protocol, such as heart rate
monitors and pulse oximeters. Examples of supported time-series are heart rate,
peripheral oxygen saturation (SpO<sub>2</sub>), Photoplethysmogram (PPG), 
battery status and more.

AsyncPulseOx is free software: you can redistribute it or modify it under the
terms of the GNU General Public License as published by the Free Software 
Foundation, version 2 only. Please check the file [COPYING](COPYING) for more
information on the license and copyright.

If you use this app in your projects and publish the results, please cite the
following manuscript:

> Villarroel, M. and Davidson, S., 2022. Open-source mobile platform for
recording physiological data. arXiv preprint arXiv:1001.0001.
<span style="color:red">(TODO: Write the paper)</span>

---

This module contains the core functinality only. Review the
[swift-pulse_ox_recorder](https://github.com/maurovm/swift-pulse_ox_recorder) 
application to  check how to use this Swift module. 
[swift-pulse_ox_recorder](https://github.com/maurovm/swift-pulse_ox_recorder) 
is the main application containing the XCode project, Settings.bundle and all 
the necessary files to build an application.

AsyncPulseOx makes use features provided by the following modules:

- [swift-sensor_recording_utils](https://github.com/maurovm/swift-sensor_recording_utils):
A module containing shared utility methods and classes used by other modules 
and applications to record raw data from sensors. 
- [swift-waveform_plotter](https://github.com/maurovm/swift-waveform_plotter): 
A library to plot physiological time-series such as the Photoplethysmogram (PPG).
- [swift-async_bluetooth](https://github.com/maurovm/swift-async_bluetooth): 
Swift Package that replicates some of the functionality provided by Apple's 
CoreBluetooth module, but using Swift's latest async/await concurrency features.

Examples of other applications making use of the above Swift Packages are:

- [swift-thermal_recorder](https://github.com/maurovm/swift-thermal_recorder): 
Record video from the thermal cameras such as the FLIR One.
- [swift-waveform_plotter_example](https://github.com/maurovm/swift-waveform_plotter_example):
Example application to showcase the features available in the "WaveformPlotter"
Swift library.

## Supported devices

All Bluetooth Low Energy devices use the Generic Attribute Profile (GATT) 
terminology. Data is transferred from a devices to a host application by 
reading the values of a given "**Characteristic**". You can check 
[https://www.bluetooth.com/specifications/specs] for the latest information 
on the Bluetooth standard

AsyncPulseOx supports recording data from the following BLE Characteristics:

- 2A37 : "Heart Rate Measurement", Version 1.0 as published by the Bluetooth
Standard on 2011/07/12
- 2A19: "Battery Level", Version 1.0 as published by the Bluetooth Standard 
on 2011/12/27
- "0AAD7EA0-0D60-11E2-8E3C-0002A5D5C51B": "Nonin Continuous Oximetry 
Characteristic", Version "113142-000-02" Rev B
- "EC0A9302-4D24-11E7-B114-B2F933D5FE66": "Nonin Device Status", Version
"113142-000-02" Rev B
- "34E27863-76FF-4F8E-96F1-9E3993AA6199" : "Nonin Pulse Interval Time", 
Version "113142-000-02" Rev B
- "EC0A883A-4D24-11E7-B114-B2F933D5FE66":  "Nonin PPG", Version "113142-000-02"
Rev B

Known pulse oximeters that support the above standards are:

- Nonin WristOx<sub>2</sub> Model 3150 with Bluetooth Low Energy Wrist-Worn
Wireless Pulse Oximeter
- Nonin 3230 Bluetooth Low Energy Wireless Pulse Oximeter