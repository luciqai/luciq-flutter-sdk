// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// luciq_flutter — Swift Package Manager manifest.
//
// This package mirrors the existing CocoaPods podspec (../luciq_flutter.podspec)
// so the plugin can be consumed in both modes. Both build systems compile the
// same sources at the paths below.
//
// Native LuciqSDK is pulled in via SPM. Confirm the upstream SPM repository
// URL and product name with the iOS SDK team before publishing — placeholders
// below.

import PackageDescription

let package = Package(
    name: "luciq_flutter",
    platforms: [
        .iOS("15.4")
    ],
    products: [
        .library(name: "luciq-flutter", targets: ["luciq_flutter"])
    ],
    dependencies: [
        .package(url: "https://github.com/luciqai/luciq-ios-sdk", exact: "19.6.1")
    ],
    targets: [
        .target(
            name: "luciq_flutter",
            dependencies: [
                // TODO(ios-sdk): confirm product name exposed by the Luciq native package.
                .product(name: "Luciq", package: "luciq-ios-sdk")
            ],
            publicHeadersPath: "include/luciq_flutter",
            cSettings: [
                .headerSearchPath("include/luciq_flutter")
            ]
        )
    ]
)
