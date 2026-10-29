// Prints the screen lock state and each normal-layer window of one process, for spanreed-verify.
//
//   window-probe <pid>
//   locked 0
//   window 17297 1 home
import CoreGraphics
import Foundation

guard CommandLine.arguments.count == 2, let pid = Int(CommandLine.arguments[1]) else {
    FileHandle.standardError.write(Data("usage: window-probe <pid>\n".utf8))
    exit(2)
}
let session = CGSessionCopyCurrentDictionary() as? [String: Any] ?? [:]
print("locked \((session["CGSSessionScreenIsLocked"] as? Bool) == true ? 1 : 0)")
let windows = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []
for window in windows where window[kCGWindowOwnerPID as String] as? Int == pid
    && window[kCGWindowLayer as String] as? Int == 0 {
    let onscreen = (window[kCGWindowIsOnscreen as String] as? Bool) == true ? 1 : 0
    print("window \(window[kCGWindowNumber as String] as? Int ?? 0) \(onscreen) \(window[kCGWindowName as String] as? String ?? "")")
}
