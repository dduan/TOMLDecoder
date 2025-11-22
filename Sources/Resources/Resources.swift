import Foundation

func stringContent(forResource name: String) -> String {
    let thisFile = URL(fileURLWithPath: #filePath)
    let thisFileDirectory = thisFile.deletingLastPathComponent()
    let resourceURL = thisFileDirectory.appendingPathComponent("fixtures").appendingPathComponent(name)
    return try! String(contentsOf: resourceURL)
}

package enum Resources {
    package static var twitterTOMLString: String {
        stringContent(forResource: "twitter.toml")
    }

    package static var canadaTOMLString: String {
        stringContent(forResource: "canada.toml")
    }
}
