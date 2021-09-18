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
    private var allTimezones: [ListTimeZone] = []
    private var topTimezones: [ListTimeZone] = []

    private var searchResults: [ListTimeZone] = []
    private var isSearchActive = false

    private let inputField = UITextField()
    private let contentView = UITableView()

    private var activeSearchTerm = ""
    private var isBaseDataLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .neutralN

        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.addTarget(self, action: #selector(onSearchTermChange), for: .editingChanged)
        inputField.font = .brandedFont(ofSize: 20, weight: .regular)
        inputField.attributedPlaceholder = NSAttributedString(string: "Search cities", attributes: [.foregroundColor: UIColor.secondary70])
        inputField.textColor = .secondary
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .sentences
        inputField.backgroundColor = .calendarGrid
        inputField.layer.cornerRadius = 12
        inputField.layer.masksToBounds = true

        let searchIconView = UIImageView(image: UIImage(named: "search")!)
        searchIconView.translatesAutoresizingMaskIntoConstraints = false
        searchIconView.contentMode = .center
        NSLayoutConstraint.activate([
            searchIconView.widthAnchor.constraint(equalToConstant: 44),
            searchIconView.heightAnchor.constraint(equalToConstant: 48)
        ])
        inputField.leftView = searchIconView
        inputField.leftViewMode = .always

        view.addSubview(inputField)

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
        contentView.backgroundColor = .neutralN
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inputField.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: 16),
            inputField.heightAnchor.constraint(equalToConstant: 48),
            contentView.topAnchor.constraint(equalTo: inputField.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        view.addPanHandle()

        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardChange), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardChange), name: UIResponder.keyboardWillHideNotification, object: nil)

        loadBaseData()
        reloadCurrentState()
    }

    private func loadBaseData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileData = try! Data(contentsOf: Bundle.main.url(forResource: "timezones-source", withExtension: "json")!)
            let list = try! JSONDecoder().decode([TimeZoneSource].self, from: fileData)
            self.allTimezones = list.compactMap {
                guard let timezone = TimeZone(identifier: $0.timezone) else { return nil }

                let hoursFromGMT = Int(round(Double(timezone.secondsFromGMT()) / 3600))
                let sign = (hoursFromGMT > 0) ? "+" : ""
                let hoursTitle = (hoursFromGMT != 0) ? "\(hoursFromGMT)" : ""

                return ListTimeZone(
                    id: $0.city.lowercased(),
                    city: $0.city,
                    country: $0.country,
                    offsetTitle: "GMT\(sign)\(hoursTitle)",
                    zoneDef: timezone
                )
            }

            let topCities = [
                "Dakar", "London", "Paris", "Cairo", "Moscow", "Baku", "Kabul", "Karachi", "Mumbai", "Kathmandu",
                "Dhaka", "Yangon", "Jakarta", "Shanghai", "Tokyo", "Brisbane", "Sydney", "Auckland",
                "Apia", "Praia", "Sao Paulo", "Santiago", "Manaus", "New York", "Mexico City", "Phoenix", "San Francisco",
                "Anchorage", "Honolulu", "Pago Pago", "Nukualofa", "Apia", "Noumea", "Papeete"
            ]
            self.topTimezones = topCities.compactMap { name in
                self.allTimezones.first { $0.city.lowercased() == name.lowercased() }
            }.sorted {
                abs($0.zoneDef.secondsFromGMT()) < abs($1.zoneDef.secondsFromGMT())
            }

            self.isBaseDataLoaded = true
            DispatchQueue.main.async {
                self.reloadCurrentState()
            }
        }
    }

    private func reloadCurrentState() {
        guard isBaseDataLoaded else {
            isSearchActive = true
            searchResults = []
            contentView.reloadData()
            return
        }

        let term = activeSearchTerm
        guard !term.isEmpty else {
            isSearchActive = false
            searchResults = []
            contentView.reloadData()
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let results = self.allTimezones.filter {
                return
                    $0.city.lowercased().contains(term.lowercased()) ||
                    $0.country.lowercased().starts(with: term.lowercased())
            }.sorted { $0.getSortRank(forTerm: term) < $1.getSortRank(forTerm: term) }
            DispatchQueue.main.async {
                if self.activeSearchTerm == term {
                    self.isSearchActive = true
                    self.searchResults = results
                    self.contentView.reloadData()
                }
            }
        }
    }

    @objc private func onSearchTermChange() {
        activeSearchTerm = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        reloadCurrentState()
    }

    @objc private func onKeyboardChange(_ notification: Notification) {
        let val = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let sf = self.view.safeAreaInsets.bottom
        let inset = self.view.window!.frame.size.height - val!.origin.y - sf
        contentView.contentInset.bottom = max(inset, 0)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchActive ? searchResults.count : topTimezones.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (isSearchActive, indexPath.row) {
        case (false, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "currentCell") as! CurrentTimezoneOptionCell
            cell.nameLabel.text = "My Timezone"
            cell.offsetLabel.text = [myTimezone.placeTitle, myTimezone.offsetTitle].joined(separator: ", ")
            cell.selectionMarkView.isHidden = myTimezone.itemId != selectionId
            return cell
        case (false, 1):
            return tableView.dequeueReusableCell(withIdentifier: "sectionCell")!
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell") as! TimezoneOptionCell
            let option = isSearchActive ? searchResults[indexPath.row] : timezoneFromAll(forRow: indexPath.row)
            cell.nameLabel.text = option.city
            cell.offsetLabel.text = option.offsetTitle
            cell.selectionMarkView.isHidden = option.id != selectionId
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .neutralN
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (isSearchActive, indexPath.row) {
        case (false, 0):
            return 64
        case (false, 1):
            return 50
        default:
            return 48
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return isSearchActive ? true : indexPath.row != 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearchActive {
            optionPickHandler?(.from(searchResults[indexPath.row]))
        } else {
            if indexPath.row == 0 {
                optionPickHandler?(myTimezone)
            } else if indexPath.row > 1 {
                optionPickHandler?(.from(timezoneFromAll(forRow: indexPath.row)))
            }
        }
        dismiss(animated: true, completion: nil)
    }

    private func timezoneFromAll(forRow row: Int) -> ListTimeZone {
        return topTimezones[row - 2]
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

private struct ListTimeZone {
    let id: String
    let city: String
    let country: String
    let offsetTitle: String
    let zoneDef: TimeZone

    func getSortRank(forTerm term: String) -> Int {
        if city.lowercased().starts(with: term.lowercased()) {
            return 1
        } else if city.lowercased().contains(term.lowercased()) {
            return 2
        } else if country.lowercased().starts(with: term.lowercased()) {
            return 3
        } else {
            return 9
        }
    }
}

private struct TimeZoneSource: Decodable {
    let city: String
    let country: String
    let timezone: String
}

private extension TimeZoneOption {
    static func from(_ entry: ListTimeZone) -> TimeZoneOption {
        return make(
            itemId: entry.id,
            zoneId: entry.zoneDef.identifier,
            placeTitle: entry.city,
            secsFromGMT: entry.zoneDef.secondsFromGMT(),
            usersTimezone: .current
        )
    }
}
