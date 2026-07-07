// swift-tools-version: 5.10
import PackageDescription
let package = Package(
    name: "NovaCam",
    platforms: [.iOS(.v17)],
    products: [.library(name:"NovaCam", targets:["NovaCam"])],
    dependencies: [],
    targets: [
        .target(name:"NovaCam", dependencies:[], path:".", exclude:["Documentation","Tests",".github"]),
        .testTarget(name:"NovaCamTests", dependencies:["NovaCam"], path:"Tests")
    ]
)
