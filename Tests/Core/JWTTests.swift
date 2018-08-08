//
//  JSONTests.swift
//  SchibstedAccount
//
//  Created by Ali Akhtarzada on 8/7/18.
//  Copyright © 2018 Schibsted. All rights reserved.
//

import Nimble
import Quick
@testable import SchibstedAccount

class JWTTests: QuickSpec {

    let jwt
        = "eyJ0eXAiOiJKV1MiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2lkZW50aXR5LXByZS5zY2hpYnN0ZWQuY29tLyIsImNsYXNzIjoidG9rZW4uT0F1dGhVc2VyQWNjZXNzVG9rZW4iLCJleHAiOjE1MzM3MjEwODQsImlhdCI6MTUzMzcxNzQ4NCwic3ViIjoiMTAxMDEwMTAtMDAwMC1mZmZmLTAwMDAtMTAxMDEwMTAxMDEwIiwiYXVkIjoiaHR0cHM6Ly9wcmUuc2RrLWV4YW1wbGUuY29tIiwic2NvcGUiOiJyYW5kb21fc2NvcGUgb3BlbmlkIiwidXNlcl9pZCI6IjEwMDAwIiwiYXpwIjoiOTEwMTkxMDE5MTAxOTEwMTkxMDE5MTAxIiwiY2xpZW50X2lkIjoiOTEwMTkxMDE5MTAxOTEwMTkxMDE5MTAxIn0.pfm2hrBYcTEqvyMpSoqc86RgdN5i72jIRy8fnCPKR-I"

    let data: JSONObject = [
        "azp": "910191019101910191019101",
        "class": "token.OAuthUserAccessToken",
        "aud": "https://pre.sdk-example.com",
        "sub": "10101010-0000-ffff-0000-101010101010",
        "client_id": "910191019101910191019101",
        "iss": "https://identity-pre.schibsted.com/",
        "iat": 1533717484,
        "scope": "random_scope openid",
        "exp": 1533721084,
        "user_id": "10000",
    ]

    override func spec() {
        describe("DefaultJWTHelperProxy") {
            it("Should turn jwt in to JSON") {
                let proxy = DefaultJWTHelperProxy()
                let json = (try? proxy.toJSON(string: self.jwt))
                expect(json).to(equal(self.data))
            }

            it("Should fail on invalid JWT") {
                let proxy = DefaultJWTHelperProxy()
                expect { try proxy.toJSON(string: "blah") }.to(throwError(JWTHelperError.invalidString("")))
            }

            it("Should fail on invalid base64 in second jwt component") {
                let proxy = DefaultJWTHelperProxy()
                expect { try proxy.toJSON(string: "blah.bl{ah.blah") }.to(throwError(JWTHelperError.componentDecodingError("")))
            }

            fit("Should fail on invalid json in second jwt component") {
                let proxy = DefaultJWTHelperProxy()
                expect { try proxy.toJSON(string: "blah.blah.blah") }.to(throwError(JSONError.parse(kDummyError)))
            }
        }
    }
}
