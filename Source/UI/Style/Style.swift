//
// Copyright 2011 - 2020 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Foundation

/**
 Style contains the diffent aspects of UI styling guidelines that we use
 */
public enum Style {
    /**
     The colors we use

     - SeeAlso `StyleColorKind`
     */
    public static let colors = StyleColors()

    /**
     The icons we use

     - SeeAlso `StyleIconKind`
     */
    public static let icons = StyleIcons()

    /**
     The font properties we use

     - SeeAlso `StyleFont`
     */
    public typealias fonts = StyleFont // swiftlint:disable:this type_name
}
