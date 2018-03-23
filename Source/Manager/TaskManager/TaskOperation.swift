//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
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

    var state: State {
        return self.lock.scope {
            if _finished {
                return .finished
            }
            if _executing {
                return .executing
            }
            return .ready
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

    public override var isAsynchronous: Bool {
        return true
    }

    private enum KVOKey: String {
        case isExecuting, isFinished, isCancelled
    }

    private var _executing: Bool = false
    public private(set) override var isExecuting: Bool {
        get {
            return self.lock.scope {
                self._executing
            }
        }
        set {
            willChangeValue(forKey: KVOKey.isExecuting.rawValue)
            self.lock.scope {
                self._executing = newValue
            }
            didChangeValue(forKey: KVOKey.isExecuting.rawValue)
        }
    }

    private var _finished: Bool = false
    public private(set) override var isFinished: Bool {
        get {
            return self.lock.scope {
                self._finished
            }
        }
        set {
            willChangeValue(forKey: KVOKey.isFinished.rawValue)
            self.lock.scope {
                self._finished = newValue
            }
            didChangeValue(forKey: KVOKey.isFinished.rawValue)
        }
    }

    public override func start() {
        guard !self.isCancelled else {
            self.isFinished = true
            return
        }
        self.isExecuting = true
        TaskOperation.sharedQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.executor({ [weak self] in self?.finish() })
        }
    }

    func finish() {
        willChangeValue(forKey: KVOKey.isExecuting.rawValue)
        willChangeValue(forKey: KVOKey.isFinished.rawValue)
        self.lock.scope {
            self._executing = false
            self._finished = true
        }
        didChangeValue(forKey: KVOKey.isExecuting.rawValue)
        didChangeValue(forKey: KVOKey.isFinished.rawValue)
    }
}
