//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

class LoadingViewController: IdentityUIViewController {
    var minShowingPeriod: TimeInterval = 1.0

    let viewModel: LoadingViewModel

    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!

    private var startTime: Date?

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, viewModel: LoadingViewModel) {
        self.viewModel = viewModel
        super.init(configuration: configuration, navigationSettings: navigationSettings, trackerViewID: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationTitle: String {
        return self.viewModel.title
    }

    override func startLoading() {
        super.startLoading()
        self.loadingIndicator.startAnimating()
        self.startTime = Date()
    }

    override func endLoading() {
        super.endLoading()
        self.view.isUserInteractionEnabled = true
        self.loadingIndicator.stopAnimating()
        self.startTime = nil
    }

    func endLoading(completion: @escaping () -> Void) {
        guard let startTime = startTime else {
            self.endLoading()
            completion()
            return
        }

        let elapsedTime = Date().timeIntervalSince(startTime)
        let remainingTime = max(self.minShowingPeriod - elapsedTime, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
            self.endLoading()
            completion()
        }
    }
}
