//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 The user profile data.

 SeeAlso: http://techdocs.spid.no/types/user/
 */
public struct UserProfile: JSONParsable {
    ///
    public var givenName: String?
    ///
    public var familyName: String?
    ///
    public var displayName: String?
    ///
    public var birthday: Birthdate?
    /// This is the email address that is marked as primary (there may or may not be one)
    public var primaryEmailAddress: EmailAddress?
    /// The email address associated with this user. For passwordless login this is generated for example.
    public var email: EmailAddress?

    ///
    public init(givenName: String? = nil, familyName: String? = nil, displayName: String? = nil, birthday: Birthdate? = nil) {
        self.familyName = familyName
        self.givenName = givenName
        self.displayName = displayName
        self.birthday = birthday
    }

    init(from json: JSONObject) throws {
        let data = try json.jsonObject(for: "data")
        let nameJson = try data.jsonObject(for: "name")

        self.displayName = try? data.string(for: "displayName")
        self.givenName = try? nameJson.string(for: "givenName")
        self.familyName = try? nameJson.string(for: "familyName")
        if let string = try? data.string(for: "birthday") {
            self.birthday = Birthdate(string: string)
        }
        if let email = try? data.string(for: "email") {
            self.email = EmailAddress(email)
        }
        if let emailJson = try? data.jsonArray(of: JSONObject.self, for: "emails") {
            for blob in emailJson {
                if (try? blob.string(for: "primary")) == "true", let email = try? blob.string(for: "value") {
                    self.primaryEmailAddress = EmailAddress(email)
                }
            }
        }
    }
}

extension UserProfile: CustomStringConvertible {
    /// human-readable string representation (YAML)
    public var description: String {
        var desc = "UserProfile:\n"
        desc = desc.appendingFormat("  givenName: %@\n", self.givenName ?? "null")
        desc = desc.appendingFormat("  familyName: %@\n", self.familyName ?? "null")
        desc = desc.appendingFormat("  displayName: %@\n", self.displayName ?? "null")
        desc = desc.appendingFormat("  birthday: %@\n", self.birthday?.description ?? "null")
        desc = desc.appendingFormat("  email: %@\n", self.email?.originalString ?? "null")
        desc = desc.appendingFormat("  primary email: %@\n", self.primaryEmailAddress?.originalString ?? "null")
        return desc
    }
}

extension UserProfile {
    enum FormDataMappings: String {
        case givenName
        case familyName
    }
    func formData(withMappings mappings: [FormDataMappings: String] = [:]) -> [String: String] {
        let nameJson = [
            mappings[.givenName] ?? FormDataMappings.givenName.rawValue: self.givenName,
            mappings[.familyName] ?? FormDataMappings.familyName.rawValue: self.familyName,
        ].compactedValues()

        var nameData: String?
        if nameJson.count > 0, let data = try? JSONSerialization.data(withJSONObject: nameJson, options: JSONSerialization.WritingOptions()) {
            nameData = String(data: data, encoding: .utf8)
        }

        var birthdayData: String?
        if let birthday = self.birthday {
            birthdayData = String(describing: birthday)
        }

        return [
            "name": nameData,
            "displayName": self.displayName,
            "birthday": birthdayData,
        ].compactedValues()
    }
}
