import Foundation

public enum SelectionResolver {
    public static func normalize(_ urls: [URL]) -> [URL] {
        let normalized = urls.map { url -> URL in
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue {
                return url.deletingLastPathComponent().resolvingSymlinksInPath()
            }

            return url.resolvingSymlinksInPath()
        }

        var seen = Set<String>()
        return normalized.filter { url in
            if seen.contains(url.path) {
                return false
            }
            seen.insert(url.path)
            return true
        }
    }
}
