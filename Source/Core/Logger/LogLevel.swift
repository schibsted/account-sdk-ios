//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Used by the logger to set various log levels. You cannot directly use this but the idea is
 that you will be able to filter based on levels if needed
*/
public enum LogLevel: String {
    /// Only logs if DEBUG is defined
    case debug = "D"
    ///
    case info = "I"
    ///
    case verbose = "V"
    ///
    case error = "E"
    ///
    case warn = "W"
}
