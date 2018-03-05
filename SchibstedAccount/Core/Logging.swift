//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 A logging class that can be told where to log to. All logs created by the SDK can be gotten
 and filtered through here.

 ## Filtering
 Every log call is automatically tagged with which thread it was called on (BG or UI),
 the function that it was called from, and the file it was called from. So if you wanted to
 only see logs from `IdentityManager` and the networking object:

     Logger.shared.addTransport { print($0) } // just print all logs
     Logger.shared.filterUnless(tags: ["Networking", "IdentityManager"])

 Two methods exist to allow for filtering of the log stream.
 - `Logger.filterUnless(tag:)`
 - `Logger.filterIf(tag:)`
 */
public class Logger {
    /// Shared logger object
    public static let shared = Logger()

    private var transports: [(String) -> Void] = []
    private var allowedTags = Set<String>()
    private var ignoredTags = Set<String>()

    /// Set to true if you want the tags to be printed as well
    public var showTags = false

    private init() {}

    func removeTransports() {
        self.transports.removeAll()
    }

    /**
     Adding a transport allows you to customize where the output goes to. You may add as
     many as you like.

     - parameter transport: function that is called with each log invocaton
     */
    public func addTransport(_ transport: @escaping (String) -> Void) {
        self.transports.append(transport)
    }

    /// Filters log messages unless they are tagged with `tag`
    public func filterUnless(tag: String) {
        self.allowedTags.insert(tag.lowercased())
    }

    /// Filters log messages unless they are tagged with any of `tags`
    public func filterUnless(tags: [String]) {
        self.allowedTags = self.allowedTags.union(tags.map { $0.lowercased() })
    }

    /// Filters log messages if they are tagged with `tag`
    public func filterIf(tag: String) {
        self.ignoredTags.insert(tag.lowercased())
    }

    /// Filters log messages if they are tagged with any of `tags`
    public func filterIf(tags: [String]) {
        self.ignoredTags = self.ignoredTags.union(tags.map { $0.lowercased() })
    }

    /**
     Logs any `T` by using string interpolation

     - parameter object: autoclosure statment to be logged
     - parameter tag: a tag to apply to this log
     */
    func log<T>(_ object: @autoclosure () -> T, tag: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        self.log(object(), tags: [tag], force: false, file, function, line)
    }

    /**
     Logs any `T` by using string interpolation

     - parameter object: autoclosure statment to be logged
     - parameter tags: a set of tags to apply to this log
     */
    func log<T>(_ object: @autoclosure () -> T, tags: [String] = [], _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        self.log(object(), tags: tags, force: false, file, function, line)
    }

    /**
     Logs any `T` by using string interpolation. This will output using `print` regardless if there're transports or not

     - parameter object: autoclosure statment to be logged
     - parameter tag: a tag to apply to this log
     */
    func forceLog<T>(_ object: @autoclosure () -> T, tag: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        self.log(object(), tags: [tag], force: true, file, function, line)
    }

    /**
     Logs any `T` by using string interpolation. This will output using `print` regardless if there're transports or not

     - parameter object: autoclosure statment to be logged
     - parameter tags: a set of tags to apply to this log
     */
    func forceLog<T>(_ object: @autoclosure () -> T, tags: [String] = [], _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        self.log(object(), tags: tags, force: true, file, function, line)
    }

    private func log<T>(_ object: @autoclosure () -> T, tags userTags: [String], force: Bool, _ file: String, _ function: String, _ line: Int) {
        guard !force && self.transports.count > 0 else {
            return
        }

        let string = "\(object())"

        let fileName: String = {
            let name = URL(fileURLWithPath: file)
                .deletingPathExtension().lastPathComponent
            let value = name.isEmpty ? "Unknown file" : name
            return value
        }()

        let functionName = function.components(separatedBy: "(")[0]
        let queue = Thread.isMainThread ? "UI" : "BG"

        var allTags = [functionName.lowercased(), fileName.lowercased(), queue.lowercased()]
        allTags.append(contentsOf: userTags.map { $0.lowercased() })

        var outputToTransports = true
        if self.ignoredTags.count > 0 && self.ignoredTags.intersection(allTags).count > 0 {
            outputToTransports = false
        }

        if self.allowedTags.count > 0 && self.allowedTags.intersection(allTags).count == 0 {
            outputToTransports = false
        }

        guard outputToTransports || force else {
            return
        }

        let threadID = pthread_mach_thread_np(pthread_self())

        var tagsString = ""
        if userTags.count > 0 && self.showTags {
            tagsString = ",\(userTags.joined(separator: ","))"
        }
        let output = "[\(queue):\(threadID),\(fileName):\(line),\(functionName)\(tagsString)] => \(string)"

        if outputToTransports {
            for transport in self.transports {
                transport(output)
            }
        }

        if force {
            print(output)
        }
    }
}

func log<T>(_ object: @autoclosure () -> T, tag: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    Logger.shared.log(object(), tag: tag, file, function, line)
}

func log<T>(_ object: @autoclosure () -> T, tags: [String] = [], _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    Logger.shared.log(object(), tags: tags, file, function, line)
}

func log<S, T>(from target: S?, _ object: @autoclosure () -> T, tag: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    log(from: target, object(), tags: [tag], file, function, line)
}

func log<S, T>(
    from target: S?,
    _ object: @autoclosure () -> T,
    tags: [String] = [],
    _ file: String = #file,
    _ function: String = #function,
    _ line: Int = #line
) {
    var tags = tags
    if let target = target {
        tags.append(String(describing: type(of: target)))
    }
    Logger.shared.log(object(), tags: tags, file, function, line)
}

func forceLog<T>(_ object: @autoclosure () -> T, tag: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    Logger.shared.forceLog(object(), tag: tag, file, function, line)
}

func forceLog<T>(_ object: @autoclosure () -> T, tags: [String] = [], _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    Logger.shared.forceLog(object(), tags: tags, file, function, line)
}

func forceLog<S, T>(from target: S?, _ object: @autoclosure () -> T, tag: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    forceLog(from: target, object(), tags: [tag], file, function, line)
}

func forceLog<S, T>(
    from target: S?,
    _ object: @autoclosure () -> T,
    tags: [String] = [],
    _ file: String = #file,
    _ function: String = #function,
    _ line: Int = #line
) {
    var tags = tags
    if let target = target {
        tags.append(String(describing: type(of: target)))
    }
    Logger.shared.forceLog(object(), tags: tags, file, function, line)
}
