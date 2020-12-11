//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class MockTask: TaskProtocol {
    var counter = AtomicInt()
    private var queue = DispatchQueue(label: "com.schibsted.account.mockTask.queue")

    var _didCancelCallCount = 0
    var _executeCallCount = 0
    var _shouldRefreshCallCount = 0
    var _failureValue: ClientError?


    var executeCallCount: Int {
        return queue.sync { _executeCallCount }
    }
    var didCancelCallCount: Int {
        return queue.sync { _didCancelCallCount }
    }
    var shouldRefreshCallCount: Int {
        return queue.sync { _shouldRefreshCallCount }
    }
    var failureValue: ClientError? {
        return queue.sync { _failureValue }
    }

    let shouldRefresh: Bool

    init(failureValue: ClientError? = nil, shouldRefresh: Bool = false) {
        self.counter.getAndIncrement()
        self._failureValue = failureValue
        self.shouldRefresh = shouldRefresh
    }

    deinit {
        self.counter.getAndDecrement()
    }

    func execute(completion: @escaping (Result<NoValue, ClientError>) -> Void) {
        queue.sync(flags: .barrier) {
            self._executeCallCount += 1
        }

        if let failureValue = self.failureValue {
            completion(.failure(failureValue))
        } else {
            completion(.success(()))
        }
        queue.sync { self._executeCallCount += 1 }
    }

    func didCancel() {
        queue.sync { self._didCancelCallCount += 1 }
    }

    func shouldRefresh(result _: Result<NoValue, ClientError>) -> Bool {
        queue.sync { self._shouldRefreshCallCount += 1 }
        return self.shouldRefresh
    }
}

class TaskManagerTests: QuickSpec {

    override func spec() {

        describe("Adding a task") {

            it("Should execute it") {
                let task =  MockTask()
                let user = User(state: .loggedIn)
                let manager = TaskManager(for: user)

                _ = manager.add(task: task) { result in
                    expect(result).to(beSuccess())
                    expect(task.executeCallCount).to(equal(1))
                }
            }

            it("Should do an automatic refresh") {
                let user = TestingUser(state: .loggedIn)

                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("valid-refresh"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                var wantedStub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                wantedStub.returnData([
                    (data: .fromFile("empty"), statusCode: 401),
                    (data: .fromFile("agreements-valid-accepted"), statusCode: 200),
                ])
                StubbedNetworkingProxy.addStub(wantedStub)

                user.agreements.status { result in
                    expect(result).to(beSuccess())
                }

                waitUntil { [unowned user] done in
                    user.wrapped.taskManager.waitForRequestsToFinish()
                    done()
                }
            }

            it("should logout after invalid refresh grant") {
                let user = TestingUser(state: .loggedIn)
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("invalid-refresh-grant"))
                stub.returnResponse(status: 400)
                StubbedNetworkingProxy.addStub(stub)

                var stubAgreements = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stubAgreements.returnData(json: .fromFile("empty"))
                stubAgreements.returnResponse(status: 401)
                StubbedNetworkingProxy.addStub(stubAgreements)

                user.agreements.status { result in
                    guard case let .failure(error) = result else {
                        return fail()
                    }
                    expect(error).to(matchError(ClientError.userRefreshFailed(kDummyError)))
                    expect(user.state).to(equal(UserState.loggedOut))
                }

                waitUntil { [unowned user] done in
                    user.wrapped.taskManager.waitForRequestsToFinish()
                    done()
                }
            }

            it("Should cancel on refresh failure") {
                let user = TestingUser(state: .loggedIn)
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("invalid-refresh-no-access-token"))
                stub.returnResponse(status: 401)
                StubbedNetworkingProxy.addStub(stub)

                var stubAgreements = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stubAgreements.returnData(json: .fromFile("empty"))
                stubAgreements.returnResponse(status: 401)
                StubbedNetworkingProxy.addStub(stubAgreements)

                user.agreements.status { result in
                    guard case let .failure(error) = result else {
                        return fail()
                    }
                    expect(error).to(matchError(ClientError.userRefreshFailed(kDummyError)))
                    expect(user.state).to(equal(UserState.loggedOut))
                }

                waitUntil { [unowned user] done in
                    user.wrapped.taskManager.waitForRequestsToFinish()
                    done()
                }
            }

            it("Should handle many requests") {
                let user = User(state: .loggedIn)
                var stub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stub.returnData(json: .fromFile("agreements-valid-accepted"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                let numRequestsToFire = 100
                var results: [Result<Bool, ClientError>] = []

                for _ in 0..<numRequestsToFire {
                    user.agreements.status { result in
                        expect(result).to(beSuccess())
                        results.append(result)
                    }
                }

                waitUntil { [unowned user] done in
                    user.taskManager.waitForRequestsToFinish()
                    done()
                }

                expect(results.count).toEventually(equal(numRequestsToFire))
            }

            it("Should handle many requests that fail") {
                let user = User(state: .loggedIn)
                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("invalid-refresh-no-access-token"))
                stub.returnResponse(status: 300)
                StubbedNetworkingProxy.addStub(stub)

                var stubAgreements = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                stubAgreements.returnData(json: .fromFile("empty"))
                stubAgreements.returnResponse(status: 401)
                StubbedNetworkingProxy.addStub(stubAgreements)

                let numRequestsToFire = 100
                var results: [Result<Bool, ClientError>] = []

                for _ in 0..<numRequestsToFire {
                    user.agreements.status { result in
                        results.append(result)
                        guard case let .failure(error) = result else {
                            return fail()
                        }
                        expect(error).to(matchError(ClientError.userRefreshFailed(kDummyError)))
                    }
                }

                waitUntil { [unowned user] done in
                    user.taskManager.waitForRequestsToFinish()
                    done()
                }

                expect(results.count).toEventually(equal(numRequestsToFire))
            }

            it("should not refresh if already in progress") {
                let user = User(state: .loggedIn)

                var stub = NetworkStub(path: .path(Router.oauthToken.path))
                stub.returnData(json: .fromFile("valid-refresh"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                var wantedStub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                wantedStub.returnData([
                    (data: .fromFile("empty"), statusCode: 401),
                    (data: .fromFile("empty"), statusCode: 401),
                    (data: .fromFile("agreements-valid-accepted"), statusCode: 200),
                ])
                StubbedNetworkingProxy.addStub(wantedStub)

                user.taskManager.willStartRefresh.register { _ in
                    // Let the other task come back as well with a 401 before we start the refresh
                    usleep(1000 * 10)
                }

                waitUntil { [unowned user] done in
                    user.taskManager.waitForRequestsToFinish()
                    done()
                }

                // Fire off two tasks that should fail with 401
                user.agreements.status { _ in }
                user.agreements.status { _ in }

                // Two failed 401 tasks
                // 1 refresh
                // Two successful 200 tasks
                expect(Networking.testingProxy.callCount).toEventually(equal(5))
                if (Networking.testingProxy.callCount == 5) {
                    expect(Networking.testingProxy.calls[0].passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain("testAccessToken"))
                    expect(Networking.testingProxy.calls[1].passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain("testAccessToken"))
                    expect(Networking.testingProxy.calls[2].passedRequest?.allHTTPHeaderFields?["Authorization"]).to(beNil())
                    expect(Networking.testingProxy.calls[3].passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain("123"))
                    expect(Networking.testingProxy.calls[4].passedRequest?.allHTTPHeaderFields?["Authorization"]).to(contain("123"))
                }
                user.taskManager.waitForRequestsToFinish()
            }
        }

        describe("Cancelling a task") {

            it("Should not call callback") {
                let user = User(state: .loggedIn)
                var stub = NetworkStub(path: .path(Router.acceptAgreements(userID: user.id!).path))
                stub.returnData(json: .fromFile("agreements-valid-accepted"))
                stub.returnResponse(status: 200)
                StubbedNetworkingProxy.addStub(stub)

                var callbackCalled = false
                let handle = user.agreements.status { _ in
                    callbackCalled = true
                }
                handle.cancel()

                waitMakeSureNot { callbackCalled }
            }

            it("Should not call callback after refresh started") {
                //
                // So... this test is a bit weird
                //
                // The idea is that there should be eventually three network calls, which includes one refresh call (ie: didStartRefresh)
                //
                // After a refresh is started, cancel is called on the handle. So after the refresh is done, this handle should in theory
                // be removed.
                //
                // The problem is that the actual User object that is created, can possible be in a "strong" state after the network proxy
                // registers its second call (ie: Networking.testingProxy.callCount is eventually 2)
                //
                // And, the returned data from the refresh call will arraive *after* the registration of actual call, so hence the
                // to *not* eventuall be nil
                //
                // We put all this in a do block so that we can check that the globally registered users is eventually nil and then we
                // make sure the callback was not called.
                //

                var callbackCalled = false
                do {
                    let user = User(state: .loggedIn)

                    var stub = NetworkStub(path: .path(Router.oauthToken.path))
                    stub.returnData(json: .fromFile("valid-refresh"))
                    stub.returnResponse(status: 200)
                    StubbedNetworkingProxy.addStub(stub)

                    var wantedStub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
                    wantedStub.returnData([
                        (data: .fromFile("empty"), statusCode: 401),
                        (data: .fromFile("agreements-valid-accepted"), statusCode: 200),
                    ])
                    StubbedNetworkingProxy.addStub(wantedStub)

                    user.taskManager.willStartRefresh.register { handle in
                        handle.cancel()
                    }

                    user.agreements.status { _ in
                        callbackCalled = true
                    }
                    expect(Networking.testingProxy.callCount).toEventually(equal(2))
                    expect(Networking.testingProxy.calls[1].returnedData).toEventuallyNot(beNil())
                }

                expect(User.globalStore.count).toEventually(equal(0))
                expect(callbackCalled).toNot(equal(true))
            }

            it("Should call the tasks cancel override") {
                let user = User(state: .loggedIn)
                let taskManager = TaskManager(for: user)
                let task = MockTask()

                let handle = taskManager.add(task: task)
                handle.cancel()

                waitTill {
                    task.didCancelCallCount == 1
                }
                taskManager.waitForRequestsToFinish()
            }

            it("should call the tasks cancel once") {
                let user = User(state: .loggedIn)
                let taskManager = TaskManager(for: user)
                let task = MockTask()

                let handle = taskManager.add(task: task)
                handle.cancel()
                handle.cancel()

                waitTill {
                    task.didCancelCallCount == 1
                }
                waitMakeSureNot {
                    task.didCancelCallCount >= 2
                }

                taskManager.waitForRequestsToFinish()
            }
        }
    }
}
