//
//  SuggestionsPickerView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/15/21.
//

import UIKit

class SuggestionsPickerView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UnstyledCalendarNavigationBlock {

    weak var navigation: CalendarNavigationCenter?

    var coordinator: SuggestionsViewCoordinator! {
        didSet {
            coordinator.onSelectionChange = { [weak self] index in
                self?.layout.focusItem(withIndex: index)
            }
        }
    }

    private let layout: SuggestionsPickerLayout

    init(parentWidth: CGFloat) {
        layout = SuggestionsPickerLayout(parentWidth: parentWidth)
        super.init(frame: .zero, collectionViewLayout: layout)
        layout.onSelectionChange = { [weak self] index in
            self?.coordinator.changeSelection(index)
        }
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didLoad() {
        register(SuggestionsPickerViewCell.self, forCellWithReuseIdentifier: "SuggestionsPickerViewCell")
        backgroundColor = .clear

        delegate = self
        dataSource = self
        decelerationRate = .fast
        showsHorizontalScrollIndicator = false

        let height = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize.height
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: "SuggestionsPickerViewCell", for: indexPath)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        layout.focusItem(withIndex: indexPath.item)
    }
}
