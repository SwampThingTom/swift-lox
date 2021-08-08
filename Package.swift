// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "swift-lox",
    products: [
        .library(
            name: "Lox",
            targets: ["Lox"]),
        .executable(
            name: "generate_ast",
            targets: ["generate_ast"]),
        .executable(
            name: "lox_cli",
            targets: ["lox_cli"])
    ],
    targets: [
        .target(name: "Lox"),
        .target(name: "generate_ast"),
        .target(name: "lox_cli", dependencies: ["Lox"])
    ]
)
