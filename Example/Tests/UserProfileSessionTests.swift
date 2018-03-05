//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation
import Mockingjay
import Nimble
import Quick
@testable import SchibstedAccount

class UserProfileSessionTests: QuickSpec {

    override func spec() {
        describe("Profile data") {
            it("Should have all the fields") {
                let user = TestingUser(state: .loggedIn)
                self.stub(uri("/api/2/user/\(user.id!)"), try! Builders.load(file: "user-profile-valid", status: 200))

                user.profile.fetch { result in
                    guard case let .success(profile) = result else {
                        return fail()
                    }
                    expect(profile.givenName) == "Gordon"
                    expect(profile.familyName) == "Freeman"
                    expect(profile.primaryEmailAddress?.originalString) == "blubberfubber@guffer.huffer"
                    expect(profile.birthday?.description) == "1999-12-12"
                }
            }
        }

        describe("Profile data update") {
            it("Should update the name successfully") {
                let user = TestingUser(state: .loggedIn)
                self.stub(uri("/api/2/user/\(user.id!)"), try! Builders.load(file: "user-profile-valid", status: 200))

                let profile = UserProfile(givenName: "Gordon", familyName: "Freeman")
                user.profile.update(profile) { result in
                    expect(result).to(beSuccess())
                }
            }
        }
    }
}
