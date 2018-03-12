//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

private class Receiver {
    var blockVoidCalls: [Void] = []
    var handlerVoidCalls: [Void] = []
    var handlerStringCalls: [String] = []
    var preCallBlock: (() -> Void)?

    init() {}

    init(preCallBlock: @escaping () -> Void) {
        self.preCallBlock = preCallBlock
    }

    func blockVoid() {
        self.preCallBlock?()
        self.blockVoidCalls.append(())
    }

    func handlerVoid(_: Void = Void()) {
        self.preCallBlock?()
        self.handlerVoidCalls.append(())
    }

    func handlerString(_ string: String) {
        self.preCallBlock?()
        self.handlerStringCalls.append(string)
    }
}

class EventEmitterTests: QuickSpec {

    override func spec() {

        describe("synchronous emitting") {

            it("Should emit to method and block") {
                let emitter = EventEmitter<Void>()
                let receiver = Receiver()
                _ = emitter.register(receiver, handler: Receiver.handlerVoid)
                _ = emitter.register(receiver.blockVoid)
                emitter.emitSync(())
                emitter.emitSync(())
                expect(receiver.handlerVoidCalls).to(haveCount(2))
                expect(receiver.blockVoidCalls).to(haveCount(2))
            }

            it("Should pass along given parameters") {
                let emitter = EventEmitter<String>()
                let receiver = Receiver()
                _ = emitter.register(receiver, handler: Receiver.handlerString)
                emitter.emitSync("hi")
                emitter.emitSync("dummy")
                expect(receiver.handlerStringCalls).to(haveCount(2))
                expect(receiver.handlerStringCalls[0]).to(equal("hi"))
                expect(receiver.handlerStringCalls[1]).to(equal("dummy"))
            }
        }

        describe("asynchronous emitting") {

            it("Should emit to method and block") {
                let emitter = EventEmitter<Void>()
                let receiver = Receiver()
                _ = emitter.register(receiver, handler: Receiver.handlerVoid)
                _ = emitter.register(receiver.blockVoid)
                emitter.emitAsync(())
                emitter.emitAsync(())
                expect(receiver.handlerVoidCalls).toEventually(haveCount(2))
                expect(receiver.blockVoidCalls).toEventually(haveCount(2))
            }

            it("Should pass along given parameters") {
                let emitter = EventEmitter<String>()
                let receiver = Receiver()
                _ = emitter.register(receiver, handler: Receiver.handlerString)
                emitter.emitAsync("hi")
                emitter.emitAsync("dummy")
                expect(receiver.handlerStringCalls).toEventually(haveCount(2))
                expect(receiver.handlerStringCalls[0]).to(equal("hi"))
                expect(receiver.handlerStringCalls[1]).to(equal("dummy"))
            }
        }

        it("Should allow to remove methods and blocks") {
            let emitter = EventEmitter<Void>()
            let receiver = Receiver()
            let h1 = emitter.register(receiver, handler: Receiver.handlerVoid)
            let h2 = emitter.register(receiver.blockVoid)
            emitter.emitSync(())
            expect(receiver.handlerVoidCalls).to(haveCount(1))
            expect(receiver.blockVoidCalls).to(haveCount(1))
            emitter.unregister(h1)
            emitter.unregister(h2)
            emitter.emitSync(())
            expect(receiver.handlerVoidCalls).to(haveCount(1))
            expect(receiver.blockVoidCalls).to(haveCount(1))
        }

        it("Should handle when receivers are deallocated") {
            var preCallBlockCount = 0
            let preCallBlock = {
                preCallBlockCount += 1
            }
            let emitter = EventEmitter<Void>()
            do {
                let receiver = Receiver(preCallBlock: preCallBlock)
                _ = emitter.register(receiver, handler: Receiver.handlerVoid)
                emitter.emitSync(())
                expect(receiver.handlerVoidCalls).to(haveCount(1))
                expect(preCallBlockCount).to(equal(1))
            }
            emitter.emitSync(())
            expect(preCallBlockCount).to(equal(1))
        }

        it("Should pass along given parameters") {
            let emitter = EventEmitter<String>()
            let receiver = Receiver()
            _ = emitter.register(receiver, handler: Receiver.handlerString)
            emitter.emitSync("hi")
            emitter.emitSync("dummy")
            expect(receiver.handlerStringCalls).to(haveCount(2))
            expect(receiver.handlerStringCalls[0]).to(equal("hi"))
            expect(receiver.handlerStringCalls[1]).to(equal("dummy"))
        }
    }
}
