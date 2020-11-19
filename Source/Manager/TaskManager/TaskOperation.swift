//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class TaskOperation: Operation {
    private let lock = NSLock()

    #if DEBUG
        static var counter = AtomicInt(0)
    #endif

    static let sharedQueue = DispatchQueue(label: "com.schibsted.identity.TaskOperation", attributes: [.concurrent])

    public enum State {
        case ready
        case executing
        case finished
    }

    private var _state: State = .ready
    var state: State {
        get {
            return lock.scope {
                self._state
            }
        }
        set {
            lock.scope {
                self._state = newValue
            }
        }
    }

    let executor: (@escaping () -> Void) -> Void

    init(executor: @escaping (@escaping () -> Void) -> Void) {
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

    override public var isAsynchronous: Bool {
        return true
    }

    private enum KVOKey: String {
        case isExecuting, isFinished, isCancelled
    }

    override public private(set) var isExecuting: Bool {
        get {
            return state == .executing
        }
        set { // swiftlint:disable:this unused_setter_value
            willChangeValue(forKey: KVOKey.isExecuting.rawValue)
            state = .executing
            didChangeValue(forKey: KVOKey.isExecuting.rawValue)
        }
    }

    override public private(set) var isFinished: Bool {
        get {
            return state == .finished
        }
        set { // swiftlint:disable:this unused_setter_value
            willChangeValue(forKey: KVOKey.isFinished.rawValue)
            state = .finished
            didChangeValue(forKey: KVOKey.isFinished.rawValue)
        }
    }

    override public func start() {
        guard !isCancelled else {
            isFinished = true
            return
        }
        isExecuting = true
        TaskOperation.sharedQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.executor { [weak self] in self?.finish() }
        }
    }

    func finish() {
        willChangeValue(forKey: KVOKey.isExecuting.rawValue)
        willChangeValue(forKey: KVOKey.isFinished.rawValue)
        isFinished = true
        didChangeValue(forKey: KVOKey.isExecuting.rawValue)
        didChangeValue(forKey: KVOKey.isFinished.rawValue)
    }
}
