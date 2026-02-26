import ProjectDescription

let organization = "com.liangzhiyuan"

let project = Project(
    name: "PathBridge",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "MACOSX_DEPLOYMENT_TARGET": "14.0",
        ]
    ),
    targets: [
        .target(
            name: "PathBridgeApp",
            destinations: .macOS,
            product: .app,
            bundleId: "\(organization).pathbridge",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "PathBridge",
                "CFBundleShortVersionString": "0.1.0",
                "CFBundleVersion": "1",
            ]),
            sources: ["Apps/PathBridgeApp/Sources/**"],
            resources: ["Apps/PathBridgeApp/Resources/**"],
            dependencies: [
                .target(name: "PathBridgeCore"),
                .target(name: "PathBridgeShared"),
                .target(name: "PathBridgeTerminalAdapters"),
                .target(name: "PathBridgeFinderExtension"),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_ENTITLEMENTS": "Apps/PathBridgeApp/PathBridgeApp.entitlements",
                ]
            )
        ),
        .target(
            name: "PathBridgeFinderExtension",
            destinations: .macOS,
            product: .appExtension,
            bundleId: "\(organization).pathbridge.findersync",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "PathBridge Finder Extension",
                "CFBundleShortVersionString": "0.1.0",
                "CFBundleVersion": "1",
                "NSExtension": [
                    "NSExtensionAttributes": [
                        "UIDisplayName": "PathBridge Finder Extension",
                    ],
                    "NSExtensionPointIdentifier": "com.apple.FinderSync",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).FinderSync",
                ],
            ]),
            sources: ["Extensions/PathBridgeFinderExtension/Sources/**"],
            resources: ["Extensions/PathBridgeFinderExtension/Resources/**"],
            dependencies: [
                .target(name: "PathBridgeCore"),
                .target(name: "PathBridgeShared"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_ENTITLEMENTS": "Extensions/PathBridgeFinderExtension/PathBridgeFinderExtension.entitlements",
                ]
            )
        ),
        .target(
            name: "PathBridgeCore",
            destinations: .macOS,
            product: .framework,
            bundleId: "\(organization).pathbridge.core",
            deploymentTargets: .macOS("14.0"),
            sources: ["Packages/Core/Sources/**"],
            dependencies: [
                .target(name: "PathBridgeShared"),
            ]
        ),
        .target(
            name: "PathBridgeShared",
            destinations: .macOS,
            product: .framework,
            bundleId: "\(organization).pathbridge.shared",
            deploymentTargets: .macOS("14.0"),
            sources: ["Packages/Shared/Sources/**"]
        ),
        .target(
            name: "PathBridgeTerminalAdapters",
            destinations: .macOS,
            product: .framework,
            bundleId: "\(organization).pathbridge.adapters",
            deploymentTargets: .macOS("14.0"),
            sources: ["Packages/TerminalAdapters/Sources/**"],
            dependencies: [
                .target(name: "PathBridgeCore"),
                .target(name: "PathBridgeShared"),
            ]
        ),
    ]
)
