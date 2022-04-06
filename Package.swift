// swift-tools-version:5.5

import PackageDescription

let package = Package(
    
    name      : "async_pulse_ox",
    platforms : [ .iOS("15.2") ],
    products  :
        [
            .library(
                name    : "AsyncPulseOx",
                targets : ["AsyncPulseOx"]
            )
        ],
    dependencies:
        [
            .package(url: "https://github.com/maurovm/sensor_recording_utils", .branch("master")),
            .package(url: "https://github.com/maurovm/async_bluetooth", .branch("master")),
.package(url: "https://github.com/maurovm/waveform_plotter", .branch("master"))
        ],
    targets:
        [
            .target(
                name         : "AsyncPulseOx",
                dependencies : 
                    [
                        .product(name: "SensorRecordingUtils", package: "sensor_recording_utils"),
                        .product(name: "AsyncBluetooth",       package: "async_bluetooth"),
                        .product(name: "WaveformPlotter",      package: "waveform_plotter")
                    ],
                path         : "Sources"
            )
        ]

)
