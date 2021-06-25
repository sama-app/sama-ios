//
//  CalendarLayout.swift
//  sama
//
//  Created by Viktoras Laukevičius on 6/8/21.
//

import UIKit

final class CalendarLayout: UICollectionViewLayout {

    let size: CGSize

    private var attrs: [UICollectionViewLayoutAttributes] = []

    init(size: CGSize) {
        self.size = size
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        let items = collectionView?.numberOfItems(inSection: 0) ?? 0

        attrs = (0 ..< items).map {
            let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: $0, section: 0))
            attrs.frame = CGRect(x: size.width * CGFloat($0), y: 0, width: size.width, height: size.height)
            return attrs
        }
    }

    override var collectionViewContentSize: CGSize {
        let items = collectionView?.numberOfItems(inSection: 0) ?? 0
        return CGSize(width: size.width * CGFloat(items), height: size.height)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let start = Int(floor(rect.origin.x / size.width))
        let length = Int(ceil(rect.width / size.width))
        let end = start + length
        return Array(attrs[start ..< end])
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return nil
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return false
    }
}
