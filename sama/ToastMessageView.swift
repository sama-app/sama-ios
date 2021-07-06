//
//  ToastMessageView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 7/6/21.
//

import UIKit

class ToastMessageView: UIView {

    private let handleToastDismiss: () -> Void

    init(message: String, handleToastDismiss: @escaping () -> Void) {
        self.handleToastDismiss = handleToastDismiss
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        let shadow = BackgroundShadowView(frame: .zero)
        shadow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shadow)
        NSLayoutConstraint.activate([
            shadow.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadow.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: shadow.trailingAnchor),
            bottomAnchor.constraint(equalTo: shadow.bottomAnchor)
        ])

        let content = UIStackView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .horizontal

        addSubview(content)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            content.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: 12),
            bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: 20)
        ])

        let label = UILabel()
        label.textColor = .base
        label.font = .brandedFont(ofSize: 20, weight: .regular)
        label.text = message
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping

        let removalButton = UIButton(type: .system)
        removalButton.addTarget(self, action: #selector(onToastDismiss), for: .touchUpInside)
        removalButton.translatesAutoresizingMaskIntoConstraints = false
        removalButton.tintColor = .primary
        removalButton.setImage(UIImage(named: "cross")!, for: .normal)
        NSLayoutConstraint.activate([
            removalButton.widthAnchor.constraint(equalToConstant: 44)
        ])

        content.addArrangedSubview(label)
        content.addArrangedSubview(removalButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onToastDismiss() {
        handleToastDismiss()
    }
}
