//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//

import UIKit

private enum ViewIndex: Int {
    case input = 1
    case error = 2
}

class RequiredFieldsViewController: IdentityUIViewController {
    enum Action {
        case update(fields: [SupportedRequiredField: String])
        case cancel
        case open(url: URL)
    }

    var didRequestAction: ((Action) -> Void)?

    @IBOutlet var subtext: TextView! {
        didSet {
            self.subtext.isEditable = false
            self.subtext.delegate = self
            self.subtext.attributedText = self.viewModel.subtext
        }
    }

    fileprivate var errorLabels: [ErrorLabel] = []
    @IBOutlet var requiredFieldsStackView: UIStackView! {
        didSet {
            let toolbar = UIToolbar.forKeyboard(
                target: self,
                doneString: self.viewModel.done,
                doneSelector: #selector(self.didTapDone),
                previousSelector: #selector(self.didTapPrevious),
                nextSelector: #selector(self.didTapNext),
                leftChevronImage: self.theme.icons.chevronLeft
            )

            self.requiredFieldsStackView.spacing = 24
            let count = self.fieldsCount
            for index in 0..<count {
                //
                // These views are arranged in a way that matches the indices in ViewIndex enum above.
                // If you change order make sure to change those as well
                //

                let field = self.viewModel.supportedRequiredFields[index]

                let title = NormalLabel()
                title.text = self.viewModel.titleForField(field)

                let input = TextField()
                input.placeholder = self.viewModel.placeholderForField(field)
                input.enableCursorMotion = field.allowsCursorMotion
                input.keyboardType = field.keyboardType
                input.clearButtonMode = .whileEditing
                input.returnKeyType = .default
                input.autocorrectionType = .no
                input.inputAccessoryView = toolbar
                // Mark this so that when it becomes active we can set the currentInputIndex on view model
                input.tag = index
                assert(input.tag >= 0)
                input.delegate = self

                let error = ErrorLabel()
                error.isHidden = true
                self.errorLabels.append(error)

                let subStack = UIStackView(arrangedSubviews: [title, input, error])
                subStack.axis = .vertical
                subStack.spacing = self.theme.geometry.titleViewSpacing

                self.requiredFieldsStackView.addArrangedSubview(subStack)
            }
        }
    }

    @IBOutlet var continueButton: PrimaryButton! {
        didSet {
            self.continueButton.setTitle(self.viewModel.proceed, for: .normal)
        }
    }

    @IBOutlet var continueButtonLayoutGuide: NSLayoutConstraint!
    var currentInputIndex: UInt = 0

    private var values: [String?]

    let viewModel: RequiredFieldsViewModel

    private var overrideScrollViewBottomContentInset: CGFloat?

    init(configuration: IdentityUIConfiguration, navigationSettings: NavigationSettings, viewModel: RequiredFieldsViewModel) {
        self.viewModel = viewModel
        self.values = [String?](repeating: nil, count: self.viewModel.supportedRequiredFields.count)
        super.init(configuration: configuration, navigationSettings: navigationSettings, trackerScreenID: .requiredFieldsForm)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didTapDone() {
        self.view.endEditing(true)
    }

    @objc func didTapNext() {
        self.gotoInput(at: (self.currentInputIndex.addingReportingOverflow(1).partialValue) % UInt(self.viewModel.supportedRequiredFields.count))
    }

    @objc func didTapPrevious() {
        self.gotoInput(at: (self.currentInputIndex.subtractingReportingOverflow(1).partialValue) % UInt(self.viewModel.supportedRequiredFields.count))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateScrollViewContentInset()
    }

    private func updateScrollViewContentInset() {
        let bottom: CGFloat

        if let override = self.overrideScrollViewBottomContentInset {
            bottom = override
        } else {
            let padding: CGFloat = 8
            let buttonY = self.view.convert(self.continueButton.frame, from: self.continueButton.superview).minY
            let buttonAreaHeight = self.view.bounds.height - buttonY + padding
            bottom = max(buttonAreaHeight, 0)
        }

        self.scrollView.contentInset.bottom = bottom
        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset
    }

    override func viewDidAppear(_: Bool) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    override func viewDidDisappear(_: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override var navigationTitle: String {
        return self.viewModel.title
    }

    @IBAction func didClickContinue(_: Any) {
        self.configuration.tracker?.interaction(.submit, with: self.trackerScreenID)

        guard let valuesToUpdate = self.valuesToUpdate() else {
            return
        }
        self.didRequestAction?(.update(fields: valuesToUpdate))
    }

    private func valuesToUpdate() -> [SupportedRequiredField: String]? {
        var invalidIndices: [(Int, String)] = []
        for (index, field) in self.viewModel.supportedRequiredFields.enumerated() {
            guard let value = self.values[index] else {
                invalidIndices.append((index, self.viewModel.string(for: .missing)))
                continue
            }
            if let error = field.validate(value: value) {
                invalidIndices.append((index, self.viewModel.string(for: error)))
            }
        }
        guard invalidIndices.count == 0 else {
            self.handleUnfilledFields(ascendingIndices: invalidIndices)
            return nil
        }

        var valuesToUpdate: [SupportedRequiredField: String] = [:]

        for (index, field) in self.viewModel.supportedRequiredFields.enumerated() {
            guard let value = self.values[index] else {
                continue
            }
            valuesToUpdate[field] = value
        }

        return valuesToUpdate
    }

    private func getActiveInput() -> UIView? {
        guard let subStack = self.requiredFieldsStackView.arrangedSubviews[Int(self.currentInputIndex)] as? UIStackView else {
            return nil
        }
        return subStack.arrangedSubviews[ViewIndex.input.rawValue]
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size,
            let activeInput = self.getActiveInput() else {
            return
        }

        self.overrideScrollViewBottomContentInset = keyboardSize.height
        self.updateScrollViewContentInset()

        var visibleFrame = self.view.frame
        visibleFrame.size.height -= keyboardSize.height

        if !visibleFrame.contains(activeInput.frame.origin) {
            self.scrollView.scrollRectToVisible(activeInput.frame, animated: true)
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        self.overrideScrollViewBottomContentInset = nil
        self.updateScrollViewContentInset()
    }

    override func startLoading() {
        super.startLoading()
        self.continueButton.isAnimating = true
    }

    override func endLoading() {
        super.endLoading()
        self.continueButton.isAnimating = false
    }
}

extension RequiredFieldsViewController: UITextViewDelegate {
    func textView(_: UITextView, shouldInteractWith url: URL, in _: NSRange) -> Bool {
        if self.viewModel.controlYouPrivacyURL == url {
            self.configuration.tracker?.engagement(.click(on: .adjustPrivacyChoices), in: self.trackerScreenID)
        } else if self.viewModel.dataAndYouURL == url {
            self.configuration.tracker?.engagement(.click(on: .learnMoreAboutSchibsted), in: self.trackerScreenID)
        }

        self.didRequestAction?(.open(url: url))
        return false
    }
}

extension RequiredFieldsViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.currentInputIndex = UInt(textField.tag)
        return true
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldText = (textField.text ?? "") as NSString
        let newText = oldText.replacingCharacters(in: range, with: string)

        guard let processedText = self.processValueForField(at: textField.tag, from: oldText as String, to: newText),
            processedText.count != newText.count else {
            return true
        }

        let beginning = textField.beginningOfDocument
        let cursorOffset: Int?
        if let start = textField.position(from: beginning, offset: range.location + range.length) {
            cursorOffset = textField.offset(from: beginning, to: start)
        } else {
            cursorOffset = nil
        }

        textField.text = processedText

        let newBeginning = textField.beginningOfDocument
        if let cursorOffset = cursorOffset,
            let newPosition = textField.position(from: newBeginning, offset: cursorOffset + (processedText.count - (oldText as String).count)) {
            textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
            return false
        }

        return true
    }

    private func processValueForField(at index: Int, from oldValue: String, to newValue: String) -> String? {
        guard index < self.viewModel.supportedRequiredFields.count else {
            return nil
        }
        guard let formattedString = self.viewModel.supportedRequiredFields[index].format(oldValue: oldValue, with: newValue) else {
            self.values[index] = newValue
            return nil
        }
        self.values[index] = formattedString
        return formattedString
    }
}

extension RequiredFieldsViewController {
    var fieldsCount: Int {
        return self.viewModel.supportedRequiredFields.count
    }

    func gotoInput(at index: UInt) {
        guard let subStack = self.requiredFieldsStackView.arrangedSubviews[Int(index)] as? UIStackView else {
            return
        }
        subStack.arrangedSubviews[ViewIndex.input.rawValue].becomeFirstResponder()
    }

    func handleUnfilledFields(ascendingIndices: [(index: Int, message: String)]) {
        // This loop sets the indices inbetween the values of ascendingIndices
        // to be hidden (since they are not the ones that were invalid)
        var currentIndex = 0
        for (invalidIndex, message) in ascendingIndices {
            while currentIndex < invalidIndex {
                self.errorLabels[currentIndex].isHidden = true
                currentIndex += 1
            }
            self.errorLabels[invalidIndex].isHidden = false
            self.errorLabels[invalidIndex].text = message
            currentIndex += 1
        }
        // And if there're any indices that we haven't gone through then
        // set those to hidden as well
        for index in currentIndex..<self.fieldsCount {
            self.errorLabels[index].isHidden = true
        }

        let errorMessages = ascendingIndices.map { self.viewModel.requiredFieldID(at: $0.index) }

        self.configuration.tracker?.error(.validation(.requiredField(errorMessages)), in: self.trackerScreenID)
    }
}
