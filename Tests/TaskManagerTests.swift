//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class MockTask: TaskProtocol {
    static var counter = AtomicInt()
    private var queue = DispatchQueue(label: "com.schibsted.account.mockTask.queue")

    private var _didCancelCallCount = 0
    private var _executeCallCount = 0
    private var _shouldRefreshCallCount = 0
    private var _failureValue: ClientError?

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
        MockTask.counter.getAndIncrement()
        self._failureValue = failureValue
        self.shouldRefresh = shouldRefresh
    }

    deinit {
        MockTask.counter.getAndDecrement()
    }

    func execute(completion: @escaping (Result<NoValue, ClientError>) -> Void) {
        queue.sync { self._executeCallCount += 1 }
        if let failureValue = self.failureValue {
            completion(.failure(failureValue))
        } else {
            completion(.success(()))
        }
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

        afterEach {
            expect(MockTask.counter.value) == 0
        }

        describe("Adding a task") {

            it("Should execute it") {
                let task = MockTask()
                let user = User(state: .loggedIn)
                let manager = TaskManager(for: user)

                _ = manager.add(task: task) { result in
                    expect(result).to(beSuccess())
                }
                waitTill {
                    task.executeCallCount == 1
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
                let results = SynchronizedArray<Result<Bool, ClientError>>()

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
                let results = SynchronizedArray<Result<Bool, ClientError>>()

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

                // Fire off two tasks that should fail with 401
                user.agreements.status { _ in }
                user.agreements.status { _ in }

                // Two failed 401 tasks
                // 1 refresh
                // Two successful 200 tasks
                expect(Networking.testingProxy.requests.count).toEventually(equal(5))
                if (Networking.testingProxy.requests.count == 5) {
                    let data = Networking.testingProxy.requests.data
                    expect(data[0].request?.allHTTPHeaderFields?["Authorization"]).to(contain("testAccessToken"))
                    expect(data[1].request?.allHTTPHeaderFields?["Authorization"]).to(contain("testAccessToken"))
                    expect(data[2].request?.allHTTPHeaderFields?["Authorization"]).to(beNil())
                    expect(data[3].request?.allHTTPHeaderFields?["Authorization"]).to(contain("123"))
                    expect(data[4].request?.allHTTPHeaderFields?["Authorization"]).to(contain("123"))
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

                let callbackCalled = Atomic<Bool>(false)
                let handle = user.agreements.status { _ in
                    callbackCalled.value = true
                }
                handle.cancel()

                waitMakeSureNot { callbackCalled.value }
            }

            // TODO: Not sure how to test this scenario reliably
//            it("Should not call callback after refresh started") {
//                //
//                // So... this test is a bit weird
//                //
//                // The idea is that there should be eventually three network calls, which includes one refresh call (ie: didStartRefresh)
//                //
//                // After a refresh is started, cancel is called on the handle. So after the refresh is done, this handle should in theory
//                // be removed.
//                //
//                // The problem is that the actual User object that is created, can possible be in a "strong" state after the network proxy
//                // registers its second call (ie: Networking.testingProxy.callCount is eventually 2)
//                //
//                // And, the returned data from the refresh call will arraive *after* the registration of actual call, so hence the
//                // to *not* eventuall be nil
//                //
//                // We put all this in a do block so that we can check that the globally registered users is eventually nil and then we
//                // make sure the callback was not called.
//                //
//
//                let callbackCalled = Atomic<Bool>(false)
//                do {
//                    let user = User(state: .loggedIn)
//
//                    var stub = NetworkStub(path: .path(Router.oauthToken.path))
//                    stub.returnData(json: .fromFile("valid-refresh"))
//                    stub.returnResponse(status: 200)
//                    StubbedNetworkingProxy.addStub(stub)
//
//                    var wantedStub = NetworkStub(path: .path(Router.agreementsStatus(userID: user.id!).path))
//                    wantedStub.returnData([
//                        (data: .fromFile("empty"), statusCode: 401),
//                        (data: .fromFile("agreements-valid-accepted"), statusCode: 200),
//                    ])
//                    StubbedNetworkingProxy.addStub(wantedStub)
//
//                    user.agreements.status { _ in
//                        callbackCalled.value = true
//                    }
//                    expect(Networking.testingProxy.responses.count).toEventually(equal(3))
//                    expect(Networking.testingProxy.responses.data[1].data).toEventuallyNot(beNil())
//                }
//
//                expect(User.globalStore.count).toEventually(equal(0))
//                expect(callbackCalled.value).toNot(equal(true))
//            }

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
