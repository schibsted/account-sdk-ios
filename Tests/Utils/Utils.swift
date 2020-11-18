//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Nimble
import Quick
import XCTest
@testable import SchibstedAccount

let kDummyError = NSError(domain: "Irrelevant NSError", code: 0, userInfo: nil)

extension Data {
    static func fromFile(_ name: String) -> Data {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        let resource = "Responses/\(name)"
        #else
        let bundle = Bundle(for: TestingUser.self)
        let resource = name
        #endif

        guard let path = bundle.path(forResource: resource, ofType: "json") else {
            preconditionFailure("Must specify a file name that exists in the test bundle")
        }

        return (try? Data(contentsOf: URL(fileURLWithPath: path))) ?? Data()
    }
}

extension Dictionary where Key == String, Value == Any {
    static func fromFile(_ name: String) -> JSONObject {
        let data = Data.fromFile(name)
        let json: JSONObject
        do {
            json = try data.jsonObject()
        } catch {
            preconditionFailure("Must specify a file name that exists in the test bundle: \(error)")
        }

        return json
    }
}

public func equal(_ expected: JSONObject?) -> Predicate<JSONObject?> {
    return Predicate { actual throws -> PredicateResult in
        let msg = ExpectationMessage.expectedActualValueTo("equal <\(expected as Any)>")
        if let actual = (try? actual.evaluate()) ?? nil {
            return PredicateResult(
                bool: actual == expected,
                message: msg
            )
        }
        return PredicateResult(
            status: .fail,
            message: msg
        )
    }
}

func beSuccess<T, E: Error>() -> Predicate<Result<T, E>> {
    return Predicate({ (expression) -> PredicateResult in
        let msg = ExpectationMessage.expectedActualValueTo("be success(\(T.self))")
        guard let actual = try expression.evaluate(), case .success = actual else {
            return PredicateResult(status: .fail, message: msg)
        }

        return PredicateResult(status: .matches, message: msg)
    })
}

func beFailure<T, E: Error>() -> Predicate<Result<T, E>> {
    return Predicate({ (expression) -> PredicateResult in
        let msg = ExpectationMessage.expectedActualValueTo("be failure")
        guard let actual = try expression.evaluate(), case .failure = actual else {
            return PredicateResult(status: .fail, message: msg)
        }

        return PredicateResult(status: .matches, message: msg)
    })
}

func failWith<T, E: Error>(_ actual: E) -> Predicate<Result<T, E>> {
    return Predicate({ (expression) -> PredicateResult in
        let msg = ExpectationMessage.expectedActualValueTo("fail with (\(actual))")
        guard case let .some(.failure(expected)) = try expression.evaluate(),
            (expected as NSError).code == (actual as NSError).code,
            (expected as NSError).domain == (actual as NSError).domain,
            "\(actual)" == "\(expected)" else {
            return PredicateResult(status: .fail, message: msg)
        }
        return PredicateResult(status: .matches, message: msg)
    })
}

func succeedWith<T: Equatable, E>(_ value: T) -> Predicate<Result<T, E>> {
    return Predicate({ (expression) -> PredicateResult in
        let msg = ExpectationMessage.expectedActualValueTo("succeed with (\(value))")
        guard let actual = try expression.evaluate(),
            case let .success(actualValue) = actual,
            actualValue == value else {
            return PredicateResult(status: .fail, message: msg)
        }
        return PredicateResult(status: .matches, message: msg)
    })
}

extension URL {
    static var localhost: URL {
        return URL(string: "https://127.0.0.1/")!
    }
}

/*
 These two functions are here because of me thinks a bug inside expect(blah).toEventually(blah)

 If you run the following code then DEINIT will never be printed and if you change the
 toEventually to just 'to' then it will print as expected.

 ```
 class Test {
   let i = 5
   init() {
     print("INIT")
   }
   deinit {
     print("DEINIT")
   }
 }

 class TestTests: QuickSpec {
   override func spec() {
     it("testing eventually") {
       let test = Test()
       expect(test.i).toEventually(equal(5))
     }
   }
 }
 ```

 */
func waitTill(_ file: StaticString = #file, _ line: UInt = #line, _ block: () -> Bool) {
    var passed = block()
    let start = Date()
    while Date().timeIntervalSince(start) < 1 && !passed {
        let ms = 1000
        usleep(useconds_t(100 * ms))
        passed = block()
    }
    if !passed {
        XCTFail("condition not met", file: file, line: line)
    }
}

func waitMakeSureNot(_ file: StaticString = #file, _ line: UInt = #line, _ block: () -> Bool) {
    var passed = block()
    let start = Date()
    while Date().timeIntervalSince(start) < 0.5 && passed {
        let ms = 1000
        usleep(useconds_t(100 * ms))
        passed = block()
    }
    if passed {
        XCTFail("condition not met", file: file, line: line)
    }
}

struct Utils {

    static func waitUntilDone<T, R>(
        _ completion: (Result<T, ClientError>) -> Void,
        _ action: @escaping (@escaping (Result<T, ClientError>) -> Void) -> R
    ) -> R {
        var maybeResult: Result<T, ClientError>?
        var returnValue: R!
        waitUntil { done in
            returnValue = action { result in
                maybeResult = result
                done()
            }
        }
        if let result = maybeResult {
            completion(result)
        } else {
            completion(.failure(ClientError.unexpected(GenericError.Unexpected("An action timed out in waitUntilDone."))))
        }
        return returnValue
    }

    static func makeIdentityManager(clientConfiguration: ClientConfiguration = .testing) -> TestingIdentityManager {
        return TestingIdentityManager(IdentityManager(clientConfiguration: clientConfiguration))
    }

    static func makeURLSession(_ configuration: URLSessionConfiguration = URLSessionConfiguration.default) -> (session: URLSession, user: User) {
        //
        // Do not use makeUser here because it returns a TestingUser, which returns a TestingUserSession
        // Which uses the Nible's waitUntil which says:
        //
        // This function manages the main run loop (`NSRunLoop.mainRunLoop()`) while this function
        // is executing. Any attempts to touch the run loop may cause non-deterministic behavior."
        //
        let user = User(clientConfiguration: .testing)
        _ = try? user.set(accessToken: "testAccessToken", refreshToken: "testRefreshToken", idToken: "testIDToken", userID: "testLegacyUserID")
        let session = URLSession(user: user, configuration: configuration)
        return (session: session, user: user)
    }

    // We set defaults like this instead of using nil and then doing var = var ?? "defaultValue" so that we can allow
    // for exlicitly setting a token to nil
    static func createDummyKeychain(
        accessToken: String = "testAccessToken",
        refreshToken: String? = "testRefreshToken",
        idToken: IDToken? = "testIdToken",
        userID: String? = "testUserID"
    ) {
        let tokenData = TokenData(accessToken: accessToken, refreshToken: refreshToken, idToken: idToken, userID: userID)
        let keychain = UserTokensKeychain()
        keychain.addTokens(tokenData)
        do {
            try keychain.saveInKeychain()
        } catch {
            fail("Error saving to keychain \(error)")
        }
    }

    static func cleanupKeychain() {
        do {
            try UserTokensKeychain().removeFromKeychain()
        } catch {
            let error = error as NSError
            if OSStatus(error.code) == errSecItemNotFound {
                return
            }
            fail("Error reading from keychain: \(error)")
        }
    }

    static func hold<T: AnyObject>(_: T) {}

    // from: https://stackoverflow.com/questions/24007461/how-to-enumerate-an-enum-with-string-type
    static func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var i = 0
        return AnyIterator {
            let next = withUnsafePointer(to: &i) {
                $0.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
            }
            if next.hashValue != i { return nil }
            i += 1
            return next
        }
    }
}
