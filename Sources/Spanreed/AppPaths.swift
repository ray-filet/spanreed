import Foundation

struct AppPaths {
    static let current = AppPaths(arguments: ProcessInfo.processInfo.arguments,
                                  environment: ProcessInfo.processInfo.environment)

    let homeNoteFolder: URL
    let configFolder: URL
    let defaults: UserDefaults

    var homeNoteURL: URL { homeNoteFolder.appendingPathComponent("Home.txt") }
    var configURL: URL { configFolder.appendingPathComponent("config") }

    init(arguments: [String], environment: [String: String]) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        func folder(argument: String, environmentKey: String, fallback: URL) -> URL {
            if let index = arguments.firstIndex(of: argument), arguments.indices.contains(index + 1) {
                return URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
            }
            if let path = environment[environmentKey] {
                return URL(fileURLWithPath: path, isDirectory: true)
            }
            return fallback
        }
        homeNoteFolder = folder(argument: "--home-note-folder", environmentKey: "SPANREED_HOME_NOTE_FOLDER",
                                fallback: home.appendingPathComponent("Documents/Spanreed", isDirectory: true))
        configFolder = folder(argument: "--config-folder", environmentKey: "SPANREED_CONFIG_FOLDER",
                              fallback: home.appendingPathComponent(".config/spanreed", isDirectory: true))
        if let suite = environment["SPANREED_DEFAULTS_SUITE"], let isolatedDefaults = UserDefaults(suiteName: suite) {
            defaults = isolatedDefaults
        } else {
            defaults = .standard
        }
    }
}
