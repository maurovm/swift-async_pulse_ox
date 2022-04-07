// swift-tools-version:5.5

import PackageDescription

let package = Package(
    
    name      : "swift-async_pulse_ox",
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
            .package(url: "https://github.com/maurovm/swift-sensor_recording_utils", .branch("master")),
            .package(url: "https://github.com/maurovm/swift-async_bluetooth",        .branch("master")),
            .package(url: "https://github.com/maurovm/swift-waveform_plotter",       .branch("master"))
        ],
    targets:
        [
            .target(
                name         : "AsyncPulseOx",
                dependencies : 
                    [
                        .product(name: "SensorRecordingUtils", package: "swift-sensor_recording_utils"),
                        .product(name: "AsyncBluetooth",       package: "swift-async_bluetooth"),
                        .product(name: "WaveformPlotter",      package: "swift-waveform_plotter")
                    ],
                path         : "Sources"
            )
        ]

)
