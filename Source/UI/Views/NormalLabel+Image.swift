//
// Copyright 2011 - 2018 Schibsted Products & Technology AS.
// Licensed under the terms of the MIT license. See LICENSE in the project root.
//


extension NormalLabel {

    func addImage(text: String, image: UIImage, imageBehindText: Bool, keepPreviousText: Bool) {
        let attachment = NSTextAttachment()
        attachment.image = image
        self.numberOfLines = 1
        // 1pt = 1.32px
        let fontSize = round(self.font.pointSize * 1.32)
        let ratio = image.size.width / image.size.height
        
        attachment.bounds = CGRect(x: 0, y: ((self.font.capHeight - fontSize) / 2).rounded(), width: ratio * fontSize, height: fontSize)
        
        let attachmentString = NSAttributedString(attachment: attachment)
        let labelText: NSMutableAttributedString
        
        if imageBehindText {
            if keepPreviousText, let lCurrentAttributedString = self.attributedText {
                labelText = NSMutableAttributedString(attributedString: lCurrentAttributedString)
                labelText.append(NSMutableAttributedString(string: text))
            } else {
                labelText = NSMutableAttributedString(string: text)
            }
            
            labelText.append(attachmentString)
            self.attributedText = labelText
        } else {
            if keepPreviousText, let currentAttributedString = self.attributedText {
                labelText = NSMutableAttributedString(attributedString: currentAttributedString)
                labelText.append(NSMutableAttributedString(attributedString: attachmentString))
                labelText.append(NSMutableAttributedString(string: text))
            } else {
                labelText = NSMutableAttributedString(attributedString: attachmentString)
                labelText.append(NSMutableAttributedString(string: text))
            }
            
            self.attributedText = labelText
        }
    }
}
