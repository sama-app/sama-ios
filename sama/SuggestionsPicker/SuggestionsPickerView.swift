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
            coordinator.onLoad = { [weak self] in
                self?.data.alternatives = $0.availableSlotProps
                self?.data.duration = $0.duration
                if $0.meetingProposalSource.isOwnMeeting {
                    self?.navigation?.showToast(withMessage: "This is your own meeting.")
                }
                self?.reloadData()
            }
            coordinator.onChange = { [weak self] index, item in
                self?.data.alternatives[index] = item
                if let cell = self?.cellForItem(at: IndexPath(item: index, section: 0)) {
                    self?.reloadCellContent(cell as! SuggestionsPickerViewCell, index: index)
                }
            }
            coordinator.onLock = { [weak self] isLocked in
                self?.isUserInteractionEnabled = !isLocked
                if !isLocked {
                    self?.visibleCells.forEach {
                        ($0 as! SuggestionsPickerViewCell).enable()
                    }
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
        clipsToBounds = true
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

        let height: CGFloat = 176
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

    func confirmSelection() {
        coordinator.confirm(recipientEmail: nil) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case let .success(result):
                let panel = TimeConfirmedPanel()
                panel.coordinator = self.coordinator
                panel.model = result
                self.navigation?.pushBlock(panel, animated: true)
            case .failure:
                self.coordinator.lockPick(false)
            }
        }
    }

    private func reloadCellContent(_ cell: SuggestionsPickerViewCell, index: Int) {
        let item = data.alternatives[index]
        let isRange = item.duration != data.duration

        cell.rangeIndication.isHidden = !isRange
        cell.confirmHandler = { [weak self] in
            guard let self = self else { return }
            self.coordinator.lockPick(true)

            if self.coordinator.meetingProposalSource.isOwnMeeting {
                let panel = MeetingInviteRecipientInputPanel()
                panel.coordinator = self.coordinator
                self.navigation?.pushBlock(panel, animated: true)
            } else {
                self.confirmSelection()
            }
        }
        cell.enable()

        let refDate = calendar.startOfDay(for: CalendarDateUtils.shared.uiRefDate)
        let startDay = calendar.date(byAdding: .day, value: item.daysOffset, to: refDate)!
        let startDate = startDay.addingTimeInterval(3600 * (item.pickStart as NSDecimalNumber).doubleValue)
        let endDate = startDate.addingTimeInterval(3600 * (data.duration as NSDecimalNumber).doubleValue)

        cell.titleLabel.text = calendar.relativeFormatted(from: refDate, to: startDay)
        cell.valueLabel.text = [
            [
                timeFormatter.string(from: startDate),
                " - ",
                timeFormatter.string(from: endDate)
            ].joined()
        ].joined(separator: " ")
    }
}
