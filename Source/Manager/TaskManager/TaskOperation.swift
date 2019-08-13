//
// Copyright 2011 - 2019 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class TaskOperation: Operation {
    private let lock = NSLock()

    #if DEBUG
        static let counter = AtomicInt(0)
    #endif

    public enum State {
        case ready
        case executing
        case finished
    }

    private var _state: State = .ready
    var state: State {
        get {
            return self.lock.scope {
                self._state
            }
        }
        set {
            self.lock.scope {
                self._state = newValue
            }
        }
    }

    let executor: () -> Void

    init(executor: @escaping () -> Void) {
        self.executor = executor
        #if DEBUG
            TaskOperation.counter.getAndIncrement()
        #endif
    }

    deinit {
        #if DEBUG
            TaskOperation.counter.getAndDecrement()
        #endif
    }

    public override var isAsynchronous: Bool {
        return true
    }

    private enum KVOKey: String {
        case isExecuting, isFinished, isCancelled
    }

    public private(set) override var isExecuting: Bool {
        get {
            return self.state == .executing
        }
        set { // swiftlint:disable:this unused_setter_value
            willChangeValue(forKey: KVOKey.isExecuting.rawValue)
            self.state = .executing
            didChangeValue(forKey: KVOKey.isExecuting.rawValue)
        }
    }

    public private(set) override var isFinished: Bool {
        get {
            return self.state == .finished
        }
        set { // swiftlint:disable:this unused_setter_value
            willChangeValue(forKey: KVOKey.isFinished.rawValue)
            self.state = .finished
            didChangeValue(forKey: KVOKey.isFinished.rawValue)
        }
    }

    public override func start() {
        defer { self.isFinished = true }
        guard !self.isCancelled else {
            return
        }
        self.isExecuting = true
        self.executor()
    }

    func finish() {
        willChangeValue(forKey: KVOKey.isExecuting.rawValue)
        willChangeValue(forKey: KVOKey.isFinished.rawValue)
        self.isFinished = true
        didChangeValue(forKey: KVOKey.isExecuting.rawValue)
        didChangeValue(forKey: KVOKey.isFinished.rawValue)
    }
}
