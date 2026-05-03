import Foundation

struct BenchmarkBuildProfile: Sendable {
    let buildConfiguration: String
    let optimizationProfile: String
    let compiledArchitecture: String
    let swiftCompilerVersion: String
    let xcodeVersion: String
    let developerDirectory: String
    let macOSSDKVersion: String
    let macOSSDKPath: String

    static let current: BenchmarkBuildProfile = {
        let developerDirectory = shellOutput("/usr/bin/xcode-select", "-p")

        return BenchmarkBuildProfile(
            buildConfiguration: buildConfiguration,
            optimizationProfile: optimizationProfile,
            compiledArchitecture: compiledArchitecture,
            swiftCompilerVersion: shellOutput("/usr/bin/xcrun", "swiftc", "--version"),
            xcodeVersion: resolvedXcodeVersion(developerDirectory: developerDirectory),
            developerDirectory: developerDirectory,
            macOSSDKVersion: shellOutput("/usr/bin/xcrun", "--sdk", "macosx", "--show-sdk-version"),
            macOSSDKPath: shellOutput("/usr/bin/xcrun", "--sdk", "macosx", "--show-sdk-path")
        )
    }()

    static let csvHeader = [
        "build_configuration",
        "optimization_profile",
        "compiled_architecture",
        "swift_compiler_version",
        "xcode_version",
        "developer_directory",
        "macos_sdk_version",
        "macos_sdk_path"
    ]

    var csvFields: [String] {
        [
            buildConfiguration,
            optimizationProfile,
            compiledArchitecture,
            swiftCompilerVersion,
            xcodeVersion,
            developerDirectory,
            macOSSDKVersion,
            macOSSDKPath
        ]
    }

    private static var buildConfiguration: String {
        #if DEBUG
        "Debug"
        #else
        "Release or custom non-Debug"
        #endif
    }

    private static var optimizationProfile: String {
        #if DEBUG
        "-Onone expected from Debug configuration"
        #else
        "-O expected from project Release configuration"
        #endif
    }

    private static var compiledArchitecture: String {
        #if arch(arm64)
        "arm64"
        #elseif arch(x86_64)
        "x86_64"
        #else
        "unknown"
        #endif
    }

    private static func resolvedXcodeVersion(developerDirectory: String) -> String {
        for xcodebuildPath in xcodebuildCandidates(developerDirectory: developerDirectory) {
            if let version = successfulShellOutput(xcodebuildPath, "-version") {
                return version
            }
        }

        if developerDirectory == "/Library/Developer/CommandLineTools" {
            return "Unavailable: Xcode.app not found; Command Line Tools are active"
        }

        return "Unavailable: Xcode.app not found"
    }

    private static func xcodebuildCandidates(developerDirectory: String) -> [String] {
        var candidates: [String] = []

        if developerDirectory.hasSuffix("/Contents/Developer") {
            candidates.append("\(developerDirectory)/usr/bin/xcodebuild")
        }

        candidates.append(contentsOf: xcodebuildsInApplicationsDirectory())

        return candidates.filter { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func xcodebuildsInApplicationsDirectory() -> [String] {
        let applicationsPath = "/Applications"

        guard let appNames = try? FileManager.default.contentsOfDirectory(atPath: applicationsPath) else {
            return []
        }

        return appNames
            .filter { $0.hasPrefix("Xcode") && $0.hasSuffix(".app") }
            .sorted()
            .map { "\(applicationsPath)/\($0)/Contents/Developer/usr/bin/xcodebuild" }
    }

    private static func successfulShellOutput(_ executable: String, _ arguments: String...) -> String? {
        runProcess(executable, arguments: arguments).flatMap { result in
            result.status == 0 ? result.output : nil
        }
    }

    private static func shellOutput(_ executable: String, _ arguments: String...) -> String {
        guard let result = runProcess(executable, arguments: arguments) else {
            return "Unavailable"
        }

        if result.status == 0 {
            return result.output
        }

        return result.error.isEmpty ? "Unavailable" : "Unavailable: \(result.error)"
    }

    private static func runProcess(_ executable: String, arguments: [String]) -> ProcessResult? {
        let process = Process()
        let output = Pipe()
        let error = Pipe()

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = error

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let outputText = String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let errorText = String(
            data: error.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return ProcessResult(status: process.terminationStatus, output: outputText, error: errorText)
    }
}

private struct ProcessResult {
    let status: Int32
    let output: String
    let error: String
}
