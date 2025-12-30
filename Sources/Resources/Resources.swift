import Foundation

func stringContent(forResource name: String) -> String {
    let thisFile = URL(fileURLWithPath: #filePath)
    let thisFileDirectory = thisFile.deletingLastPathComponent()
    let resourceURL = thisFileDirectory.appendingPathComponent("fixtures").appendingPathComponent(name)
    return try! String(contentsOf: resourceURL, encoding: .utf8)
}

public enum Resources {
    public static var twitterTOMLString: String {
        stringContent(forResource: "twitter.toml")
    }

    public static var canadaTOMLString: String {
        stringContent(forResource: "canada.toml")
    }

    public static var eventArchiveTOMLString: String {
        stringContent(forResource: "github-events-archive.toml")
    }
}
