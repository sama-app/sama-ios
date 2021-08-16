//
//  SuggestionsPickerLayout.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/16/21.
//

import UIKit

class SuggestionsPickerLayout: UICollectionViewFlowLayout {

    let sideInset: CGFloat

    private var focusedIndex = 0

    private let cardSize = CGSize(width: 272, height: 156)
    private let cardInset: CGFloat = 8
    private var itemWidth: CGFloat {
        cardSize.width + cardInset * 2
    }

    init(parentWidth: CGFloat) {
        self.sideInset = (parentWidth - cardSize.width) / 2
        super.init()
        itemSize = cardSize
        minimumLineSpacing = cardInset * 2
        sectionInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
        scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func focusItem(withIndex index: Int) {
        collectionView?.setContentOffset(setFocusedIndex(from: index), animated: true)
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var newIndex = focusedIndex
        if (velocity.x > 0.01) {
            newIndex += 1
        } else if (velocity.x < 0.01) {
            newIndex -= 1
        }
        return setFocusedIndex(from: newIndex)
    }

    private func setFocusedIndex(from index: Int) -> CGPoint {
        let numberOfItems = collectionView?.numberOfItems(inSection: 0) ?? 0
        focusedIndex = max(min(index, numberOfItems - 1), 0)
        return CGPoint(x: CGFloat(focusedIndex) * itemWidth, y: 0)
    }
}
