import Foundation
import XCTest
@testable import PathBridgeCore

final class SelectionResolverTests: XCTestCase {
    func test_fileSelection_resolvesToParentDirectory() throws {
        let fixture = try Fixture()
        let resolved = SelectionResolver.normalize([fixture.realFileURL])

        XCTAssertEqual(resolved.map(\.path), [fixture.realDirectoryURL.path])
    }

    func test_duplicateSelection_isDeduplicatedAfterSymlinkResolution() throws {
        let fixture = try Fixture()
        let resolved = SelectionResolver.normalize([fixture.symlinkFileURL, fixture.realFileURL])

        XCTAssertEqual(resolved.map(\.path), [fixture.realDirectoryURL.path])
    }
}

private struct Fixture {
    let rootURL: URL
    let realDirectoryURL: URL
    let realFileURL: URL
    let symlinkDirectoryURL: URL
    let symlinkFileURL: URL

    init() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        realDirectoryURL = rootURL.appendingPathComponent("real", isDirectory: true)
        realFileURL = realDirectoryURL.appendingPathComponent("demo.txt", isDirectory: false)
        symlinkDirectoryURL = rootURL.appendingPathComponent("link", isDirectory: true)
        symlinkFileURL = symlinkDirectoryURL.appendingPathComponent("demo.txt", isDirectory: false)

        try FileManager.default.createDirectory(at: realDirectoryURL, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: realFileURL.path, contents: Data("ok".utf8))
        try FileManager.default.createSymbolicLink(at: symlinkDirectoryURL, withDestinationURL: realDirectoryURL)
    }
}
