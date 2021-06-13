//
//  UIView+Helpers.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/12/21.
//

import UIKit

extension UIView {

    @discardableResult
    func addBackButton(action: Selector) -> UIButton {
        let backBtn = UIButton(type: .system)
        backBtn.addTarget(self, action: action, for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.tintColor = .primary
        backBtn.setImage(UIImage(named: "arrow-back")!, for: .normal)
        addSubview(backBtn)
        NSLayoutConstraint.activate([
            backBtn.widthAnchor.constraint(equalToConstant: 44),
            backBtn.heightAnchor.constraint(equalToConstant: 44),
            backBtn.topAnchor.constraint(equalTo: topAnchor, constant: -4),
            backBtn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -8)
        ])
        return backBtn
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
