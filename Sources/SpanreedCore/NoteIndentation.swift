import Foundation

public enum NoteIndentation {
    public struct Edit {
        public let range: NSRange
        public let replacement: String
        public let selection: NSRange
    }

    /// Removes one tab stop, using four spaces per stop, from each selected line.
    /// A selection ending at the next line's start does not include that line.
    public static func outdent(_ text: String, selection: NSRange) -> Edit? {
        let original = text as NSString
        guard selection.location >= 0, selection.location <= original.length,
              selection.length >= 0, selection.length <= original.length - selection.location else { return nil }
        let firstLine = original.lineRange(for: NSRange(location: selection.location, length: 0))
        let lastPosition = selection.location + max(0, selection.length - 1)
        let lastLine = original.lineRange(for: NSRange(location: lastPosition, length: 0))
        let range = NSRange(location: firstLine.location, length: NSMaxRange(lastLine) - firstLine.location)
        var removals: [NSRange] = []
        var lineStart = range.location
        while lineStart < NSMaxRange(range) {
            let line = original.lineRange(for: NSRange(location: lineStart, length: 0))
            var count = 0
            while count < 4, lineStart + count < NSMaxRange(line) {
                let character = original.character(at: lineStart + count)
                if character == 9 {
                    count += 1
                    break
                }
                guard character == 32 else { break }
                count += 1
            }
            if count > 0 { removals.append(NSRange(location: lineStart, length: count)) }
            lineStart = NSMaxRange(line)
        }
        guard !removals.isEmpty else { return nil }

        let replacement = NSMutableString(string: original.substring(with: range))
        for removal in removals.reversed() {
            replacement.deleteCharacters(in: NSRange(location: removal.location - range.location, length: removal.length))
        }
        func adjusted(_ position: Int) -> Int {
            position - removals.reduce(0) { total, removal in
                total + min(max(position - removal.location, 0), removal.length)
            }
        }
        let start = adjusted(selection.location)
        let end = adjusted(NSMaxRange(selection))
        return Edit(range: range, replacement: replacement as String,
                    selection: NSRange(location: start, length: end - start))
    }
}
