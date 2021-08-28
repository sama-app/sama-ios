//
//  UIView+Helpers.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/12/21.
//

import UIKit

extension UIView {

    @discardableResult
    func addBackButton(title: String? = nil, action: Selector) -> UIButton {
        let backBtn = UIButton(type: .system)
        backBtn.addTarget(self, action: action, for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.tintColor = .primary
        backBtn.setImage(UIImage(named: "arrow-back")!, for: .normal)
        if let btnTitle = title {
            backBtn.setTitle(btnTitle, for: .normal)
            backBtn.titleLabel?.font = .brandedFont(ofSize: 20, weight: .semibold)
            backBtn.titleEdgeInsets.left = 8
            backBtn.titleEdgeInsets.right = -8
            backBtn.contentEdgeInsets.right = 8
        }
        addSubview(backBtn)
        NSLayoutConstraint.activate([
            backBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            backBtn.heightAnchor.constraint(equalToConstant: 44),
            backBtn.topAnchor.constraint(equalTo: topAnchor, constant: -4),
            backBtn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -8)
        ])
        return backBtn
    }

    @discardableResult
    func addMainActionButton(title: String, action: Selector, topAnchor: NSLayoutYAxisAnchor) -> MainActionButton {
        let actionBtn = MainActionButton.make(withTitle: title)
        actionBtn.addTarget(self, action: action, for: .touchUpInside)
        addSubview(actionBtn)
        NSLayoutConstraint.activate([
            actionBtn.heightAnchor.constraint(equalToConstant: 48),
            actionBtn.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            actionBtn.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: actionBtn.trailingAnchor),
            bottomAnchor.constraint(equalTo: actionBtn.bottomAnchor)
        ])
        return actionBtn
    }

    @discardableResult
    func addPanelContentTableView(
        withLeftView leftView: UIView,
        withDelegate delegate: (UITableViewDataSource & UITableViewDelegate)
    ) -> UITableView {
        let contentView = UITableView()
        contentView.register(HighlightableSimpleCell.self, forCellReuseIdentifier: "cell")
        contentView.dataSource = delegate
        contentView.delegate = delegate
        contentView.separatorStyle = .none
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.showsVerticalScrollIndicator = false
        contentView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
        contentView.contentOffset = CGPoint(x: 0, y: -12)
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 376),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: -16),
            contentView.leadingAnchor.constraint(equalTo: leftView.trailingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
        return contentView
    }
}
