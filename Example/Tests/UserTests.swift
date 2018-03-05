//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Mockingjay
import Nimble
import Quick
@testable import SchibstedAccount

class UserTests: QuickSpec {

    override func spec() {

        describe("Refreshing") {

            it("Should refresh internal properties") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "valid-refresh", status: 200))

                let user = TestingUser(state: .loggedIn)

                let oldTokens = user.wrapped.tokens
                expect(oldTokens?.accessToken).toNot(beNil())
                expect(oldTokens?.refreshToken).toNot(beNil())

                user.refresh { expect($0).to(beSuccess()) }

                let newTokens = user.wrapped.tokens
                expect(newTokens?.accessToken).toNot(beNil())
                expect(newTokens?.accessToken).toNot(equal(oldTokens?.accessToken))
                expect(newTokens?.refreshToken).toNot(beNil())
                expect(newTokens?.refreshToken).toNot(equal(oldTokens?.refreshToken))
            }

            it("Should emit set event when session refreshes it") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "valid-refresh", status: 200))
                let user = TestingUser(state: .loggedIn)
                let oldTokens = user.wrapped.tokens
                var newTokens: TokenData?
                _ = user.wrapped.didSetTokens.register { newTokens = $0.new }
                user.refresh { _ in }
                expect(newTokens).toNot(beNil())
                expect(oldTokens).toNot(equal(newTokens))
            }

            it("Should handle when the refresh_token is missing") {
                self.stub(uri("/oauth/token"), try! Builders.load(file: "invalid-refresh-no-refresh-token", status: 200))
                let user = TestingUser(state: .loggedIn)
                user.refresh { result in
                    expect(result).to(failWith(.unexpected(JSONError.noKey("refreshToken"))))
                }
            }
        }

        describe("Logging out") {

            it("Should change state") {
                let user = User(state: .loggedIn)
                expect(user.state).to(equal(UserState.loggedIn))
                let delegate = TestingUserDelegate()
                user.delegate = delegate
                user.logout()
                expect(delegate.stateChangedData.count) == 1
                expect(delegate.stateChangedData[0]) == UserState.loggedOut
            }

            it("Should not change state again") {
                let user = User(state: .loggedIn)
                let delegate = TestingUserDelegate()
                user.delegate = delegate
                user.logout()
                expect(delegate.stateChangedData.count) == 1
                user.logout()
                waitMakeSureNot {
                    delegate.stateChangedData.count >= 2
                }
            }

            it("Should unset tokens") {
                let user = User(state: .loggedIn)
                user.logout()
                expect(user.tokens).to(beNil())
            }

            it("Should not emit logout if already logged out") {
                let user = TestingUser(state: .loggedOut)
                let delegate = TestingUserDelegate()
                user.delegate = delegate
                user.logout()
                waitMakeSureNot {
                    delegate.stateChangedData.count >= 1
                }
            }

            it("Should fire the API logout call asynchronously") {
                self.stub(uri("/api/2/logout"), Builders.load(string: "", status: 200))
                let user = TestingUser(state: .loggedIn)
                user.logout()
                expect(Networking.testingProxy.calledOnce).toEventually(beTrue())
            }
        }

        describe("Setting tokens") {

            it("Should change state") {
                let user = TestingUser(state: .loggedOut)
                expect(user.state).to(equal(UserState.loggedOut))
                let delegate = TestingUserDelegate()
                user.delegate = delegate
                _ = try? user.wrapped.set(accessToken: "hehe", refreshToken: "hehe", idToken: "hehe")
                expect(delegate.stateChangedData.count).toEventually(equal(1))
                expect(delegate.stateChangedData[0]) == UserState.loggedIn
            }

            it("Should not change state again") {
                let user = TestingUser(state: .loggedIn)
                let delegate = TestingUserDelegate()
                user.delegate = delegate
                _ = try? user.wrapped.set(accessToken: "hehe", refreshToken: "hehe", idToken: "hehe")
                expect(delegate.stateChangedData.count).toEventually(equal(1))
                _ = try? user.wrapped.set(accessToken: "hehe", refreshToken: "hehe", idToken: "hehe")
                expect(delegate.stateChangedData.count).toNotEventually(equal(2))
            }

            it("Should add user to store") {
                let user1 = TestingUser(state: .loggedIn, id: "id1")
                let user2 = TestingUser(state: .loggedIn, id: "id2")
                Utils.hold(user1)
                Utils.hold(user2)
                expect(User.globalStore.count).to(equal(2))
            }

            it("Should throw if any access or refresh missing") {
                let user = TestingUser(state: .loggedOut)
                expect { try user.wrapped.set() }.to(throwError(User.Failure.missingToken("", "")))
                expect { try user.wrapped.set(accessToken: "haha") }.to(throwError(User.Failure.missingToken("", "")))
                expect { try user.wrapped.set(refreshToken: "haha") }.to(throwError(User.Failure.missingToken("", "")))
            }

            it("Should throw if either idToken or legacyUserID not provided") {
                let user = User(state: .loggedOut)
                expect { try user.set(accessToken: "haha", refreshToken: "haha") }.to(throwError(User.Failure.missingUserID))
            }

            it("Should set other id to nil if only one provided") {
                let user = User(state: .loggedIn)
                expect(user.tokens?.idToken).toNot(beNil())
                expect(user.tokens?.userID).toNot(beNil())
                try! user.set(idToken: "new")
                expect(user.tokens?.idToken) == "new"
                expect(user.tokens?.userID).to(beNil())
                try! user.set(userID: "new")
                expect(user.tokens?.idToken).to(beNil())
                expect(user.tokens?.userID) == "new"
            }

            it("Should have correct info in missing tokens error") {
                let user = User(state: .loggedOut)
                expect { try user.set() }.to(throwError { expect("\($0)").to(contain(" accessToken,refreshToken")) })
                expect { try user.set(accessToken: "haha") }.to(throwError { expect("\($0)").to(contain(" refreshToken")) })
                expect { try user.set(refreshToken: "haha") }.to(throwError { expect("\($0)").to(contain(" accessToken")) })
                expect { try user.set(accessToken: "haha", idToken: "haha") }.to(throwError { expect("\($0)").to(contain(" refreshToken")) })
            }

            it("Should be set if all tokens set with id token") {
                let user = User(state: .loggedOut)
                expect(user.tokens).to(beNil())
                _ = try? user.set(accessToken: "hehe", refreshToken: "hehe", idToken: "hehe")
                expect(user.tokens).toNot(beNil())
            }

            it("Should be set if all tokens set with legacy user id") {
                let user = User(state: .loggedOut)
                expect(user.tokens).to(beNil())
                _ = try? user.set(accessToken: "hehe", refreshToken: "hehe", userID: "hehe")
                expect(user.tokens).toNot(beNil())
            }

            it("Should emit set event") {
                let user = User(state: .loggedOut)
                var newTokens: TokenData?
                _ = user.didSetTokens.register { newTokens = $0.new }
                _ = try? user.set(accessToken: "hehe", refreshToken: "hehe", idToken: "hehe")
                expect(newTokens).toNot(beNil())
            }

            it("Should not emit set event if set to same") {
                let user = User(state: .loggedOut)
                var newTokens: TokenData?
                _ = try? user.set(accessToken: "hehe", refreshToken: "hehe", idToken: "hehe")
                _ = user.didSetTokens.register { newTokens = $0.new }
                _ = try? user.set(accessToken: "hehe", refreshToken: "hehe", idToken: "hehe")
                expect(newTokens).to(beNil())
            }

            it("Should emit set event if any tokens set differently") {
                let user = User(state: .loggedOut)
                var newTokens: TokenData?
                _ = try? user.set(accessToken: "hehe", refreshToken: "hehe", idToken: "hehe", userID: "hehe")
                _ = user.didSetTokens.register { newTokens = $0.new }

                _ = try? user.set(accessToken: "hehe again")
                expect(newTokens).toNot(beNil())
                newTokens = nil

                _ = try? user.set(refreshToken: "hehe again")
                expect(newTokens).toNot(beNil())
                newTokens = nil

                _ = try? user.set(idToken: "hehe again")
                expect(newTokens).toNot(beNil())
                newTokens = nil

                _ = try? user.set(userID: "hehe again")
                expect(newTokens).toNot(beNil())
            }
        }

        describe("Creating user") {

            it("Should have tokens unset") {
                let user = User(state: .loggedOut)
                expect(user.tokens).to(beNil())
            }

            it("Should add to global store") {
                let user1 = User(state: .loggedOut)
                let user2 = User(state: .loggedOut)
                Utils.hold(user1)
                Utils.hold(user2)
                expect(User.globalStore.count).to(equal(2))
            }

            it("Should be in logged out state") {
                let user = User(state: .loggedOut)
                expect(user.state).to(equal(UserState.loggedOut))
            }
        }

        describe("Destructing user") {

            it("Should remove user from store") {
                do {
                    let user1 = User(state: .loggedIn, id: "id1")
                    let user2 = User(state: .loggedIn, id: "id2")
                    Utils.hold(user1)
                    Utils.hold(user2)
                    expect(User.globalStore.count).to(equal(2))
                }
                expect(User.globalStore.count).to(equal(0))
            }
        }

        describe("Getting ID") {

            it("Should return nil if logged out") {
                let user = User(state: .loggedOut)
                expect(user.id).to(beNil())
            }

            it("Should return subject id if id token set") {
                let user = User(state: .loggedIn, id: "subjectID")
                expect(user.id).to(equal("subjectID"))
            }

            it("Should return subject id if id token set") {
                let user = User(state: .loggedOut)
                _ = try? user.set(accessToken: "heh", refreshToken: "whatevs", userID: "testLegacyUserID")
                expect(user.id).to(equal("testLegacyUserID"))
            }
        }
    }
}
