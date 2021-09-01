//
//  HighlightableSimpleCell.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/12/21.
//

import UIKit

class HighlightableSimpleCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.alpha = highlighted ? 0.35 : 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentView.alpha = selected ? 0.35 : 1
    }
}
