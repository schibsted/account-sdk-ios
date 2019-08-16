//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class TaskOperation: Operation {
    enum ExecuteResult {
        case done
        case running
    }

    private let lock: NSLocking = NSLock()

    #if DEBUG
        static var counter = AtomicInt(0)
    #endif

    enum State: String {
        case pending = "isPending"
        case ready = "isReady"
        case executing = "isExecuting"
        case finished = "isFinished"
    }

    private var _state: State = .pending

    private(set) var state: State {
        get {
            return self.lock.scope {
                self._state
            }
        }

        set {
            willChangeValue(forKey: newValue.rawValue)
            self.lock.scope {
                self._state = newValue
                log(level: .verbose, from: self, "set \(self).state to \(newValue)")
            }
            didChangeValue(forKey: newValue.rawValue)
        }
    }

    let executor: () -> ExecuteResult

    init(executor: @escaping () -> ExecuteResult) {
        self.executor = executor
        #if DEBUG
            TaskOperation.counter.getAndIncrement()
        #endif
    }

    #if DEBUG
        deinit {
            TaskOperation.counter.getAndDecrement()
        }
    #endif

    override var isAsynchronous: Bool {
        return true
    }

    override var isReady: Bool {
        return self.state == .ready
    }

    override var isExecuting: Bool {
        return self.state == .executing
    }

    override var isFinished: Bool {
        return self.state == .finished
    }

    override func start() {
        assert(self.state == .ready || self.isCancelled)
        log(level: .debug, from: self, "starting \(self)")
        guard !self.isCancelled else {
            log(level: .debug, from: self, "cancelled, aborting \(self)")
            self.state = .finished
            return
        }
        log(level: .debug, from: self, "executing \(self)")
        self.state = .executing
        if case .done = self.executor() {
            self.finish()
        }
    }

    func finish() {
        log(level: .debug, from: self, "finishing \(self)")
        self.state = .finished
    }

    func markReady() {
        assert(self.state == .pending)
        log(level: .debug, from: self, "readying \(self)")
        self.state = .ready
    }

    override var description: String {
        #if DEBUG
            if let name = self.name {
                return name
            }
        #endif
        return super.description
    }
}
