//
//  SuggestionsPickerView.swift
//  sama
//
//  Created by Viktoras Laukevičius on 8/15/21.
//

import UIKit

class SuggestionsDataHolder {
    var alternatives: [ProposedAvailableSlot] = []
    var duration: Decimal = 0
}

class SuggestionsPickerView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UnstyledCalendarNavigationBlock {

    weak var navigation: CalendarNavigationCenter?

    var coordinator: SuggestionsViewCoordinator! {
        didSet {
            coordinator.onSelectionChange = { [weak self] index in
                self?.layout.focusItem(withIndex: index)
            }
            coordinator.onLoad = { [weak self] alternatives, duration in
                self?.data.alternatives = alternatives
                self?.data.duration = duration
                self?.reloadData()
            }
            coordinator.onChange = { [weak self] index, item in
                self?.data.alternatives[index] = item
                if let cell = self?.cellForItem(at: IndexPath(item: index, section: 0)) {
                    self?.reloadCellContent(cell as! SuggestionsPickerViewCell, index: index)
                }
            }
        }
    }

    private let data = SuggestionsDataHolder()
    private let calendar = Calendar.current

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
        return data.alternatives.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: "SuggestionsPickerViewCell", for: indexPath) as! SuggestionsPickerViewCell
        reloadCellContent(cell, index: indexPath.item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        layout.focusItem(withIndex: indexPath.item)
    }

    private func reloadCellContent(_ cell: SuggestionsPickerViewCell, index: Int) {
        let item = data.alternatives[index]
        let isRange = item.duration != data.duration
        cell.titleLabel.text = "Alternative \(index + 1)"
        cell.rangeIndication.isHidden = !isRange

        let refDate = calendar.startOfDay(for: Date())
        let startDay = calendar.date(byAdding: .day, value: item.daysOffset, to: refDate)!
        let startDate = startDay.addingTimeInterval(3600 * (item.pickStart as NSDecimalNumber).doubleValue)
        let endDate = startDate.addingTimeInterval(3600 * (data.duration as NSDecimalNumber).doubleValue)

        cell.valueLabel.text = [
            calendar.relativeFormatted(from: refDate, to: startDay),
            [
                timeFormatter.string(from: startDate),
                "-",
                timeFormatter.string(from: endDate)
            ].joined()
        ].joined(separator: " ")
    }
}