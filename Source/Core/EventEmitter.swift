//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/*
 A lot of code here is explained in Mike Ash's "Let's Build Swift Notifications" article:
 https://mikeash.com/pyblog/friday-qa-2015-01-23-lets-build-swift-notifications.html
 */

class ReceiverHandle<Parameters>: Hashable {
    fileprivate weak var object: AnyObject?
    fileprivate var objectHandler: ((AnyObject) -> (Parameters) -> Void)?
    fileprivate var block: ((Parameters) -> Void)?

    var descriptionText: String

    fileprivate init(object: AnyObject, handler: @escaping (AnyObject) -> (Parameters) -> Void) {
        self.object = object
        self.objectHandler = handler
        self.descriptionText = "AnyObject"
    }

    fileprivate init(block: @escaping (Parameters) -> Void) {
        self.block = block
        self.descriptionText = "block"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(Unmanaged.passUnretained(self).toOpaque())
    }
}

func == <P>(lhs: ReceiverHandle<P>, rhs: ReceiverHandle<P>) -> Bool {
    return lhs === rhs
}

class EventEmitter<Parameters> {
    private let dispatchQueue = DispatchQueue(label: "com.schibsted.identity.EventEmitter", attributes: [])
    private var handles = Set<ReceiverHandle<Parameters>>()
    private var descriptionText: String

    init(description: String) {
        self.descriptionText = description
    }

    init() {
        self.descriptionText = "\(EventEmitter<Parameters>.self)"
    }

    @discardableResult
    func register(_ block: @escaping (Parameters) -> Void) -> ReceiverHandle<Parameters> {
        let handle = ReceiverHandle<Parameters>(block: block)
        _ = self.dispatchQueue.sync {
            self.handles.insert(handle)
        }
        return handle
    }

    func register<T: AnyObject>(_ object: T, handler: @escaping (T) -> (Parameters) -> Void) -> ReceiverHandle<Parameters> {
        let typeErasedHandler: (AnyObject) -> (Parameters) -> Void = { any in
            /*
             We need this wrapped up because the ReceiverHandle expects type: AnyObject -> Parameters -> Void
             but here we have a type: T -> Parameters -> Void. So we make a "wrapped" function that takes a type
             erased T and calls handler on the actual type T.
             */
            handler(any as! T) // swiftlint:disable:this force_cast
        }
        let handle = ReceiverHandle<Parameters>(object: object, handler: typeErasedHandler)
        _ = self.dispatchQueue.sync {
            self.handles.insert(handle)
        }
        return handle
    }

    func unregister(_ handle: ReceiverHandle<Parameters>) {
        _ = self.dispatchQueue.sync {
            self.handles.remove(handle)
        }
    }

    func compactAndTakeHandles() -> [ReceiverHandle<Parameters>] {
        var validHandles: [ReceiverHandle<Parameters>] = []
        self.dispatchQueue.sync {
            for handle in self.handles {
                if handle.block != nil || handle.object != nil {
                    validHandles.append(handle)
                }
            }
            // No point in leaving invalid handles in the set
            self.handles = Set(validHandles)
        }
        return validHandles
    }

    func normalizeHandlers(in handles: [ReceiverHandle<Parameters>]) -> [(ReceiverHandle<Parameters>, (Parameters) -> Void)] {
        return handles.compactOrFlatMap { (handle) -> (ReceiverHandle<Parameters>, (Parameters) -> Void)? in
            var maybeHandler: ((Parameters) -> Void)?
            if let block = handle.block {
                maybeHandler = block
            } else if let object = handle.object, let objectHandler = handle.objectHandler {
                maybeHandler = objectHandler(object)
            }
            guard let handler = maybeHandler else {
                return nil
            }
            return (handle, handler)
        }
    }

    func emitSync(_ parameters: Parameters) {
        log(level: .verbose, from: self, "\(self.descriptionText) on \(self.handles.count) handles")
        let handles = self.compactAndTakeHandles()
        self.normalizeHandlers(in: handles).forEach { handle, handler in
            log(level: .debug, from: self, "\(self.descriptionText) -> \(handle.descriptionText)")
            handler(parameters)
        }
    }

    func emitAsync(_ parameters: Parameters) {
        log(level: .verbose, from: self, "\(self.descriptionText) on \(self.handles.count) handles")
        let handles = self.compactAndTakeHandles()
        let normalizedHandlers = self.normalizeHandlers(in: handles)
        self.dispatchQueue.async { [weak self] in
            normalizedHandlers.forEach { handle, handler in
                log(level: .debug, from: self, "\(self?.descriptionText as Any) -> \(handle.descriptionText)")
                handler(parameters)
            }
        }
    }
}
