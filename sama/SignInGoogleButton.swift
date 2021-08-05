//
//  SignInGoogleButton.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/5/21.
//

import UIKit

class SignInGoogleButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            changeBgOpacity()
        }
    }
    override var isEnabled: Bool {
        didSet {
            changeBgOpacity()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "sign-in-google")
        setBackgroundImage(image, for: .normal)
        setBackgroundImage(image, for: .highlighted)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func changeBgOpacity() {
        alpha = (isHighlighted || !isEnabled) ? 0.4 : 1
    }
}
