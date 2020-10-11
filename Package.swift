// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SchibstedAccount",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v9),
    ],
    products: [
        .library(name: "SchibstedAccount", targets: ["SchibstedAccount"])
    ],
    dependencies: [
        .package(name: "Quick", url: "https://github.com/Quick/Quick.git", from: "3.0.0"),
        .package(name: "Nimble", url: "https://github.com/Quick/Nimble.git", from: "9.0.0"),
    ],
    targets: [
        .target(name: "SchibstedAccount",
                path: "Source",
                exclude: [
                    "Info.plist",
                    "UI/Resources/Info.plist",
                    "Manager/LegacySPiDAccessToken",
                ],
                resources: [
                    .copy("Manager/Configuration.plist"),
                ]
        ),
        .testTarget(name: "SchibstedAccountTests",
                    dependencies: ["SchibstedAccount", "Quick", "Nimble"],
                    path: "Tests",
                    exclude: [
                        "Info.plist"
                    ],
                    resources: [
                        .process("Responses"),
                    ]
        )
    ],
    swiftLanguageVersions: [.v4_2]
)

