//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

class TaskManager {
    struct TaskData {
        let operation: TaskOperation
        let errorCallback: ((ClientError) -> Void)?
        let taskDidCancelCallback: (() -> Void)?
        let retryCount: Int
        let taskReference: AnyObject
    }

    private var pendingTasks: [OwnedTaskHandle: TaskData] = [:]
    private let operationQueue = OperationQueue()
    private let lock = NSLock()
    private weak var user: User?
    private var operationsToReAdd: [TaskOperation] = []

    func waitForRequestsToFinish() {
        self.operationQueue.waitUntilAllOperationsAreFinished()
    }

    var willStartRefresh = EventEmitter<TaskHandle>(description: "TaskManager.willStartRefresh")

    init(for user: User) {
        self.user = user
    }

    func add<T: TaskProtocol>(task: T, completion: ((Result<T.SuccessType, ClientError>) -> Void)? = nil) -> TaskHandle {
        let handle = OwnedTaskHandle(owner: self)

        let executor: (@escaping () -> Void) -> Void = { [weak self, weak handle, weak task] done in
            defer { done() }
            guard self != nil else {
                log("executor() => task manager dead")
                return
            }
            guard let task = task else {
                log(from: self, "executor() => task dead")
                return
            }
            task.execute { [weak self, weak task] result in
                guard let strongSelf = self else {
                    log("task.execute => task manager dead")
                    return
                }

                guard let handle = handle else {
                    log(from: self, "task.execute => handle dead")
                    return
                }

                guard let task = task else {
                    log(from: self, "task.execute => task dead")
                    return
                }

                if task.shouldRefresh(result: result) {
                    log(from: self, "task.execute => need to refresh on \(handle)")
                    strongSelf.refresh(handle: handle)
                    return
                }

                log(from: self, "done with \(handle)")

                strongSelf.lock.scope {
                    //
                    // It's possible here that the refresh call above fails and the queue is restarted while the tasks
                    // are being cancelled. So check here that the handle we want to remove is actually still there.
                    //
                    if strongSelf.pendingTasks.removeValue(forKey: handle) != nil {
                        log(from: self, "removed \(handle)")
                        DispatchQueue.main.async {
                            completion?(result)
                        }
                    } else {
                        log(from: self, "did not find \(handle)")
                    }
                }
            }
        }

        let taskData = TaskData(
            operation: TaskOperation(executor: executor),
            errorCallback: {
                completion?(.failure($0))
            },
            taskDidCancelCallback: { [weak task] in task?.didCancel() },
            retryCount: 0,
            taskReference: task
        )

        self.lock.scope {
            log(from: self, "adding \(handle)")
            self.operationQueue.addOperation(taskData.operation)
            self.pendingTasks[handle] = taskData
        }

        return handle
    }

    func refresh(handle: OwnedTaskHandle) {
        guard let user = self.user else {
            log(from: self, "user dead. kthxbye.")
            return
        }

        do {
            self.lock.lock()
            defer { self.lock.unlock() }

            // If it was cancelled and removed there's no need to refresh
            guard let taskData = self.pendingTasks[handle] else {
                log(from: self, "\(handle) gone. No need to refresh")
                return
            }

            // If retry count exceeded, cancel it, we're done
            if let maxRetryCount = user.auth.refreshRetryCount,
                taskData.retryCount >= maxRetryCount,
                let data = self.pendingTasks.removeValue(forKey: handle) {
                log(from: self, "refresh retry count for \(handle) exceeeded")
                DispatchQueue.main.async {
                    let userInfo: [AnyHashable: Any] = [
                        NSLocalizedDescriptionKey: "Refresh retry count exceeded",
                    ]
                    let error = NSError(
                        domain: ClientError.domain,
                        code: ClientError.RefreshRetryExceededCode,
                        userInfo: userInfo as? [String: Any]
                    )
                    data.errorCallback?(.userRefreshFailed(error))
                }
                return
            }

            let refreshInProgress = self.operationQueue.isSuspended
            log(from: self, refreshInProgress ? "refresh already in progress" : "suspending queue")
            self.operationQueue.isSuspended = true

            log(from: self, "re-adding \(handle)")
            let newOperation = TaskOperation(executor: taskData.operation.executor)

            let newData = TaskData(
                operation: newOperation,
                errorCallback: taskData.errorCallback,
                taskDidCancelCallback: taskData.taskDidCancelCallback,
                retryCount: taskData.retryCount + 1,
                taskReference: taskData.taskReference
            )

            self.pendingTasks[handle] = newData
            self.operationsToReAdd.append(newOperation)

            guard !refreshInProgress else {
                return
            }
        }

        self.willStartRefresh.emitSync(handle)

        user.refresh { [weak self] result in
            guard let strongSelf = self else {
                return
            }

            do {
                try result.materialize()

                strongSelf.lock.lock()
                defer { strongSelf.lock.unlock() }

                log(from: self, "unsuspending queue")
                strongSelf.operationQueue.isSuspended = false
                strongSelf.operationQueue.addOperations(strongSelf.operationsToReAdd, waitUntilFinished: false)
                strongSelf.operationsToReAdd.removeAll()
            } catch {
                strongSelf.lock.lock()
                log(from: strongSelf, "removing \(strongSelf.pendingTasks.count) pending tasks")
                let allHandles = strongSelf.pendingTasks
                strongSelf.pendingTasks.removeAll()
                strongSelf.operationsToReAdd.removeAll()
                strongSelf.operationQueue.isSuspended = false
                strongSelf.lock.unlock()

                allHandles.forEach {
                    $1.operation.cancel()
                }

                DispatchQueue.main.async { [weak self] in
                    log(from: self, "calling \(allHandles.count) error callbacks")
                    for (_, state) in allHandles {
                        state.errorCallback?(.userRefreshFailed(error))
                    }
                }

                if let clientError = error as? ClientError {
                    switch clientError {
                    case let .networkingError(internaleError):
                        let logoutCodes = [400, 401, 403]
                        if case let NetworkingError.unexpectedStatus(status, _) = internaleError, logoutCodes.contains(status) {
                            strongSelf.user?.logout()
                        }
                    case .invalidClientCredentials:
                        strongSelf.user?.logout()
                        //
                        // HACK HACK HACK!
                        //
                        // this is a hack for now. oauth/token returns invalid_grant when the grant type is authorization_code
                        // and the code is wrong, and it returns invalid_grant when the authorization_type is refresh_token
                        // and the token is invalid. They are parsed as invalidCode inside IdentityAPI error handling, but invalidCode
                        // is for a client to see, where as a refresh failure should not have a corresponding ClientError and there's
                        // no way (short of if-else hacks on the form_data that is passed to the requstor) to distinguish the two
                        // cases. So for now we handle it here until someone thinks of a better way
                        //
                    case .invalidCode:
                        strongSelf.user?.logout()
                    default:
                        break
                    }
                }
            }
        }
    }

    func cancel(handle handleToCancel: OwnedTaskHandle) {
        let maybeData = self.lock.scope {
            self.pendingTasks.removeValue(forKey: handleToCancel)
        }
        guard let taskData = maybeData else {
            log(from: self, "\(handleToCancel) not found")
            return
        }
        log(from: self, "cancelling \(handleToCancel)")

        taskData.operation.cancel()
        taskData.taskDidCancelCallback?()
    }
}
