//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class OwnedTaskHandle: TaskHandle {
    private weak var owner: TaskManager?

    fileprivate let identifier: Int
    static var counter = AtomicInt()

    init(owner: TaskManager) {
        self.identifier = type(of: self).counter.getAndIncrement()
        self.owner = owner
    }

    func cancel() {
        self.owner?.cancel(handle: self)
    }
}

extension OwnedTaskHandle: CustomStringConvertible {
    var description: String {
        return "task.handle.\(self.identifier)"
    }
}

extension OwnedTaskHandle: Hashable {
    var hashValue: Int {
        return self.identifier
    }

    static func == (lhs: OwnedTaskHandle, rhs: OwnedTaskHandle) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
