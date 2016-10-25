import PackageDescription

let package = Package(
    name: "Silica",
    targets: [
      Target(
          name: "Silica")
    ],
    dependencies: [
        .Package(url: "https://github.com/astrotuna201/Cairo.git", majorVersion: 1)
    ],
    exclude: ["Xcode"]
)