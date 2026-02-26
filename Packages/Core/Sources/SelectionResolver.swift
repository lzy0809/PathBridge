import Foundation

public enum SelectionResolver {
    public static func normalize(_ urls: [URL]) -> [URL] {
        let resolved = urls.map { url -> URL in
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue {
                return url.deletingLastPathComponent()
            }
            return url
        }

        var seen = Set<String>()
        return resolved.filter { url in
            let key = url.resolvingSymlinksInPath().path
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
}
