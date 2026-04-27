// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BluetoothRemoteCam",
    platforms: [.iOS(.v15)],
    products: [.library(name: "BluetoothRemoteCam", targets: ["BluetoothRemoteCam"])],
    targets: [.target(name: "BluetoothRemoteCam", path: ".")]
)
