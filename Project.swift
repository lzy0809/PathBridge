import ProjectDescription

let organization = "com.liangzhiyuan"

let project = Project(
    name: "PathBridge",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "MACOSX_DEPLOYMENT_TARGET": "14.0",
            "DEVELOPMENT_TEAM": "6K9FQJ7SA2",
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
                "NSAppleEventsUsageDescription": "PathBridge needs Finder automation permission to read the current Finder folder and open it in your selected terminal.",
            ]),
            sources: ["Apps/PathBridgeApp/Sources/**"],
            resources: ["Apps/PathBridgeApp/Resources/**"],
            dependencies: [
                .target(name: "PathBridgeCore"),
                .target(name: "PathBridgeShared"),
                .target(name: "PathBridgeTerminalAdapters"),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_ENTITLEMENTS": "Apps/PathBridgeApp/PathBridgeApp.entitlements",
                    "DEVELOPMENT_TEAM": "6K9FQJ7SA2",
                ]
            )
        ),
        .target(
            name: "PathBridgeLauncher",
            destinations: .macOS,
            product: .app,
            bundleId: "\(organization).pathbridge.launcher",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "PathBridge Launcher",
                "CFBundleShortVersionString": "0.1.0",
                "CFBundleVersion": "1",
                "LSUIElement": true,
                "NSAppleEventsUsageDescription": "PathBridge Launcher needs access to Finder to read current directory and open terminal.",
            ]),
            sources: ["Apps/PathBridgeLauncher/Sources/**"],
            resources: ["Apps/PathBridgeLauncher/Resources/**"],
            dependencies: [
                .target(name: "PathBridgeCore"),
                .target(name: "PathBridgeShared"),
                .target(name: "PathBridgeTerminalAdapters"),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_ENTITLEMENTS": "Apps/PathBridgeLauncher/PathBridgeLauncher.entitlements",
                    "DEVELOPMENT_TEAM": "6K9FQJ7SA2",
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
                    "DEVELOPMENT_TEAM": "6K9FQJ7SA2",
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
        .target(
            name: "PathBridgeSharedTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "\(organization).pathbridge.shared.tests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Packages/Shared/Tests/**"],
            dependencies: [
                .target(name: "PathBridgeShared"),
            ]
        ),
        .target(
            name: "PathBridgeCoreTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "\(organization).pathbridge.core.tests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Packages/Core/Tests/**"],
            dependencies: [
                .target(name: "PathBridgeCore"),
            ]
        ),
        .target(
            name: "PathBridgeTerminalAdaptersTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "\(organization).pathbridge.adapters.tests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Packages/TerminalAdapters/Tests/**"],
            dependencies: [
                .target(name: "PathBridgeTerminalAdapters"),
                .target(name: "PathBridgeShared"),
            ]
        ),
        .target(
            name: "PathBridgeAppTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "\(organization).pathbridge.app.tests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Apps/PathBridgeApp/Tests/**"],
            dependencies: [
                .target(name: "PathBridgeApp"),
                .target(name: "PathBridgeShared"),
                .target(name: "PathBridgeTerminalAdapters"),
                .target(name: "PathBridgeCore"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "PathBridgeApp",
            shared: true,
            buildAction: .buildAction(targets: ["PathBridgeApp"]),
            testAction: .targets(
                [
                    "PathBridgeAppTests",
                    "PathBridgeSharedTests",
                    "PathBridgeCoreTests",
                    "PathBridgeTerminalAdaptersTests",
                ],
                configuration: .debug
            ),
            runAction: .runAction(configuration: .debug, executable: "PathBridgeApp"),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release, executable: "PathBridgeApp"),
            analyzeAction: .analyzeAction(configuration: .debug)
        ),
        .scheme(
            name: "PathBridgeLauncher",
            shared: true,
            buildAction: .buildAction(targets: ["PathBridgeLauncher"]),
            runAction: .runAction(configuration: .debug, executable: "PathBridgeLauncher"),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release, executable: "PathBridgeLauncher"),
            analyzeAction: .analyzeAction(configuration: .debug)
        ),
    ]
)
