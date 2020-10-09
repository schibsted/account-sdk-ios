// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SchibstedAccount",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "SchibstedAccount", targets: ["SchibstedAccount"])
    ],
    targets: [
        .target(name: "SchibstedAccount",
                path: "Source",
                exclude: ["Info.plist",
                          "UI/Resources/Info.plist",
                          "Manager/Configuration.plist"])
    ]
)

