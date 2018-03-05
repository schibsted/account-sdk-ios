//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Birthdate that can be full date or just month/day

 - SeeAlso: https://tools.ietf.org/html/draft-smarr-vcarddav-portable-contacts-00#section-7.2.1
 */
public enum Birthdate: CustomStringConvertible {
    /// The year, month and day are all valid
    case full(String)
    /// Only month and day are valid
    case day(String)

    init?(string: String) {
        let parts = string.components(separatedBy: "-")

        guard parts.count == 3 else {
            return nil
        }

        let dateFormatter = DateFormatter()
        if parts[0] == "0000" {
            dateFormatter.dateFormat = "MM-dd"
            guard dateFormatter.date(from: parts[1...].joined(separator: "-")) != nil else {
                return nil
            }
            self = .day(string)
        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard dateFormatter.date(from: string) != nil else {
                return nil
            }
            self = .full(string)
        }
    }

    ///
    public var description: String {
        switch self {
        case let .full(string):
            return string
        case let .day(string):
            return "0000-" + string
        }
    }
}
