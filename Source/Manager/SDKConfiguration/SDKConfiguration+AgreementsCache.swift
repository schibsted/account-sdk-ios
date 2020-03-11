//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

private extension DateFormatter {
    static let local: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()
}

private enum Keys {
    static let agreementsData = "user-agreements-data"
    enum Data {
        static let userID = "user-id"
        static let date = "date"
        static let agreements = "agreements"
    }
}

extension SDKConfiguration {
    /// How agreements are cached
    public struct AgreementsCache {
        static let `default` = AgreementsCache(
            isOn: true,
            minDays: 1,
            maxDays: 7
        )

        /// Whether caching is enabled or not
        public let isOn: Bool
        /// Minimum number of days agreements status should be cached
        public let minDays: UInt32
        /// Maximum number of days agreements status should be cached
        public let maxDays: UInt32

        func load(forUserID userID: String) -> Agreements? {
            guard isOn, let data = Settings.value(forKey: Keys.agreementsData) as? JSONObject else {
                return nil
            }
            do {
                let storedID = try data.string(for: Keys.Data.userID)
                guard storedID == userID else {
                    return nil
                }
                guard let date = DateFormatter.local.date(from: try data.string(for: Keys.Data.date)) else {
                    return nil
                }
                guard date > Date() else {
                    return nil
                }
                return try Agreements(from: data.jsonObject(for: Keys.Data.agreements))
            } catch {
                log(from: self, "failed to find agreements in cache \(error)")
                return nil
            }
        }

        func store(_ agreements: Agreements, forUserID userID: String) {
            guard isOn else {
                return
            }
            let now = Date()
            let hoursPerDay: UInt32 = 24
            let number = Int(arc4random_uniform(UInt32(maxDays - minDays) * hoursPerDay) + minDays * hoursPerDay)
            guard let later = Calendar.current.date(byAdding: .hour, value: number, to: now) else {
                return
            }
            let json: JSONObject = [
                Keys.Data.userID: userID,
                Keys.Data.date: DateFormatter.local.string(from: later),
                Keys.Data.agreements: agreements.toJSON(),
            ]
            Settings.setValue(json, forKey: Keys.agreementsData)
        }
    }
}
