//
//  TimezonePickerViewController.swift
//  sama
//
//  Created by Viktoras Laukevičius on 9/1/21.
//

import UIKit

class TimezonePickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var optionPickHandler: ((TimeZoneOption) -> Void)?
    var selectionId: String?

    private let myTimezone = TimeZoneOption.from(timeZone: .current, usersTimezone: .current)
    private let allTimezones: [TimeZoneOption] = TimeZone.knownTimeZoneIdentifiers.map {
        TimeZoneOption.from(timeZone: TimeZone(identifier: $0)!, usersTimezone: .current)
    }.sorted { $0.hoursFromGMT < $1.hoursFromGMT }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .neutralN

        let contentView = UITableView()
        contentView.register(CurrentTimezoneOptionCell.self, forCellReuseIdentifier: "currentCell")
        contentView.register(TimezoneOptionCell.self, forCellReuseIdentifier: "optionCell")
        contentView.register(TimezonesSectionHeaderCell.self, forCellReuseIdentifier: "sectionCell")
        contentView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        contentView.contentOffset = CGPoint(x: 0, y: -8)
        contentView.dataSource = self
        contentView.delegate = self
        contentView.separatorStyle = .none
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.showsVerticalScrollIndicator = false
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        view.addPanHandle()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTimezones.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "currentCell") as! CurrentTimezoneOptionCell
            cell.nameLabel.text = "My Timezone"
            cell.offsetLabel.text = [myTimezone.placeTitle, myTimezone.offsetTitle].joined(separator: ", ")
            cell.selectionMarkView.isHidden = myTimezone.id != selectionId
            return cell
        case 1:
            return tableView.dequeueReusableCell(withIdentifier: "sectionCell")!
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell") as! TimezoneOptionCell
            let option = timezoneFromAll(forRow: indexPath.row)
            cell.nameLabel.text = option.placeTitle
            cell.offsetLabel.text = option.offsetTitle
            cell.selectionMarkView.isHidden = option.id != selectionId
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 64
        case 1:
            return 50
        default:
            return 48
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            optionPickHandler?(myTimezone)
        } else if indexPath.row > 1 {
            optionPickHandler?(timezoneFromAll(forRow: indexPath.row))
        }
        dismiss(animated: true, completion: nil)
    }

    private func timezoneFromAll(forRow row: Int) -> TimeZoneOption {
        return allTimezones[row - 2]
    }
}

class TimezonesSectionHeaderCell: UITableViewCell {

    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .secondary
        nameLabel.font = .brandedFont(ofSize: 14, weight: .semibold)
        nameLabel.attributedText = NSAttributedString(string: "RECIPIENT TIMEZONE", attributes: [.kern: 1.5])

        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 68),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TimezoneOptionCell: HighlightableSimpleCell {

    let selectionMarkView = UIImageView(image: UIImage(named: "check")!)
    let nameLabel = UILabel()
    let offsetLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionMarkView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .primary
        nameLabel.font = .brandedFont(ofSize: 20, weight: .semibold)

        offsetLabel.translatesAutoresizingMaskIntoConstraints = false
        offsetLabel.textColor = .secondary
        offsetLabel.font = .systemFont(ofSize: 15, weight: .regular)

        contentView.addSubview(selectionMarkView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(offsetLabel)

        NSLayoutConstraint.activate([
            selectionMarkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            selectionMarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 68),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            offsetLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            offsetLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CurrentTimezoneOptionCell: HighlightableSimpleCell {

    let selectionMarkView = UIImageView(image: UIImage(named: "check")!)
    let nameLabel = UILabel()
    let offsetLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionMarkView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .primary
        nameLabel.font = .brandedFont(ofSize: 20, weight: .semibold)

        offsetLabel.translatesAutoresizingMaskIntoConstraints = false
        offsetLabel.textColor = .secondary
        offsetLabel.font = .systemFont(ofSize: 15, weight: .regular)

        let textsStack = UIStackView()
        textsStack.axis = .vertical
        textsStack.translatesAutoresizingMaskIntoConstraints = false
        textsStack.addArrangedSubview(nameLabel)
        textsStack.addArrangedSubview(offsetLabel)
        contentView.addSubview(textsStack)
        contentView.addSubview(selectionMarkView)

        NSLayoutConstraint.activate([
            selectionMarkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            selectionMarkView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            textsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 68),
            textsStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
