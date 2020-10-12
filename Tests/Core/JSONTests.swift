//
//  JSONTests.swift
//  SchibstedAccount
//
//  Created by Ali Akhtarzada on 8/7/18.
//  Copyright © 2018 Schibsted. All rights reserved.
//

import Foundation
import Nimble
import Quick
@testable import SchibstedAccount

class JSONTests: QuickSpec {

    override func spec() {
        it("Should convert to Data and convert back correctly") {
            let json: JSONObject? = ["key": 0]
            let data = json?.data() ?? Data()
            expect { try data.jsonObject() }.to(equal(json))
        }

        it("Should throw if invalid Data") {
            let data = "data".data(using: .utf8)!
            expect { try data.jsonObject() }.to(throwError(JSONError.parse(kDummyError)))
        }

        describe("Types") {

            it("Should handle string") {
                let val = "string"
                let ok: JSONObject = ["key": val]
                expect { try ok.string(for: "key") }.to(equal(val))
                let bad: JSONObject = ["key": 3]
                expect { try bad.string(for: "key") }.to(throwError(JSONError.notString("")))
            }

            it("Should handle json object") {
                let val: JSONObject = ["key": 3]
                let ok: JSONObject = ["key": val]
                expect { try ok.jsonObject(for: "key") }.to(equal(val))
                let bad: JSONObject = ["key": 3]
                expect { try bad.jsonObject(for: "key") }.to(throwError(JSONError.notJSONObject("")))
            }

            it("Should handle number") {
                let val: Double = 3
                let ok: JSONObject = ["key": val]
                expect { try ok.number(for: "key") }.to(equal(val))
                let bad: JSONObject = ["key": "yo"]
                expect { try bad.number(for: "key") }.to(throwError(JSONError.notNumber("")))
            }

            it("Should handle json array") {
                let val = [1, 2, 3]
                let ok: JSONObject = ["key": val]
                expect { try ok.jsonArray(of: Int.self, for: "key") }.to(equal(val))
                expect { try ok.jsonArray(of: String.self, for: "key") }.to(throwError(JSONError.notArrayOf("Int", forKey: "")))
                let bad: JSONObject = ["key": "yo"]
                expect { try bad.jsonArray(of: Int.self, for: "key") }.to(throwError(JSONError.notArrayOf("Int", forKey: "")))
            }

            it("Should handle boolean") {
                let val = true
                let ok: JSONObject = ["key": val]
                expect { try ok.boolean(for: "key") }.to(equal(val))
                let bad: JSONObject = ["key": "yo"]
                expect { try bad.boolean(for: "key") }.to(throwError(JSONError.notBoolean("")))
            }
        }
    }
}
