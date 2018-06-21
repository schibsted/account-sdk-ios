//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import Nimble
import Quick
@testable import SchibstedAccount

private class MyThemeable: UIView, Themeable {
    var appliedTheme = false
    func applyTheme(theme _: IdentityUITheme) {
        self.appliedTheme = true
    }
}

private class MyViewController: IdentityUIViewController {
    var optional: MyThemeable?
    var nilOptional: MyThemeable?
    var implicitlyUnrappedOptional: MyThemeable!
    var nilImplicitlyUnrappedOptional: MyThemeable!
    var nonOptional: MyThemeable
    init() {
        self.optional = MyThemeable()
        self.nilOptional = nil
        self.implicitlyUnrappedOptional = MyThemeable()
        self.nilImplicitlyUnrappedOptional = nil
        self.nonOptional = MyThemeable()
        super.init(configuration: .testing, navigationSettings: NavigationSettings(), trackerScreenID: .accountVerification)
    }

    override func loadView() {
        self.view = UIView()
        self.view.addSubview(self.optional!)
        self.view.addSubview(self.implicitlyUnrappedOptional)
        self.view.addSubview(self.nonOptional)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override static var nibName: String? {
        return nil
    }
}

class IdentityUIViewControllerTests: QuickSpec {

    override func spec() {

        it("Should call all themeable views on viewDidLoad") {
            let vc = MyViewController()
            expect(vc.optional?.appliedTheme) == false
            expect(vc.nilOptional).to(beNil())
            expect(vc.implicitlyUnrappedOptional.appliedTheme) == false
            expect(vc.nilImplicitlyUnrappedOptional).to(beNil())
            expect(vc.nonOptional.appliedTheme) == false
            vc.viewDidLoad()
            expect(vc.optional?.appliedTheme) == true
            expect(vc.nilOptional).to(beNil())
            expect(vc.implicitlyUnrappedOptional.appliedTheme) == true
            expect(vc.nilImplicitlyUnrappedOptional).to(beNil())
            expect(vc.nonOptional.appliedTheme) == true
        }
    }
}
