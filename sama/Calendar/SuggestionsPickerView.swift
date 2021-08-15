//
//  SuggestionsPickerView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/15/21.
//

import UIKit

class SuggestionsPickerViewCell: UICollectionViewCell {

}

class SuggestionsPickerView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UnstyledCalendarNavigationBlock {

    weak var navigation: CalendarNavigationCenter?

    init(parentWidth: CGFloat) {
        let width: CGFloat = 272
        let sideInset = (parentWidth - width) / 2
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 272, height: 156)
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
        layout.scrollDirection = .horizontal

        super.init(frame: .zero, collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didLoad() {
        register(SuggestionsPickerViewCell.self, forCellWithReuseIdentifier: "SuggestionsPickerViewCell")
        backgroundColor = .clear

        delegate = self
        dataSource = self
        showsHorizontalScrollIndicator = false

        let height = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize.height
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: "SuggestionsPickerViewCell", for: indexPath)
        cell.backgroundColor = .white
        return cell
    }
}
