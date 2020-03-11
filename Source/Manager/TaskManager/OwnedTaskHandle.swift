//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class OwnedTaskHandle: TaskHandle {
    private weak var owner: TaskManager?

    fileprivate let identifier: Int
    static var counter = AtomicInt()

    init(owner: TaskManager) {
        identifier = type(of: self).counter.getAndIncrement()
        self.owner = owner
    }

    func cancel() {
        owner?.cancel(handle: self)
    }
}

extension OwnedTaskHandle: CustomStringConvertible {
    var description: String {
        return "task.handle.\(identifier)"
    }
}

extension OwnedTaskHandle: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: OwnedTaskHandle, rhs: OwnedTaskHandle) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
