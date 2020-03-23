//
//  StatisticsView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import SnapKit

struct StatisticsRow {
    var name: String? = nil
    var weight: String? = nil
    var area: String? = nil
    var statisticalAccuracy: String? = nil
    var localFatness: String? = nil
    var polygonalComplexity: String? = nil
    var backgroundColor: UIColor? = nil
}

class StatisticsView: UIView {
    let columns: [KeyPath<StatisticsRow, String?>]
    let header: StatisticsRow
    var rows: [StatisticsRow] {
        didSet {
            self.stackView.arrangedSubviews.dropFirst(self.rows.count).forEach({
                self.stackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            })

            for row in self.rows.dropFirst(self.stackView.arrangedSubviews.count) {
                let view = StatisticsRowView(row: row, columns: self.columns)
                self.stackView.addArrangedSubview(view)
                view.align(with: self.headerRowView)
            }

            for (view, row) in zip(self.stackView.arrangedSubviews, self.rows) {
                (view as! StatisticsRowView).row = row
            }
        }
    }
    var footer: StatisticsRow {
        didSet { self.footerRowView.row = self.footer }
    }

    private let separatorView = UIView()
    private let verticalSeparatorView: [UIView]
    private let headerRowView: StatisticsRowView
    private let stackView = UIStackView()
    private var regularRowViews: [StatisticsRowView]
    private var footerRowView: StatisticsRowView

    init(header: StatisticsRow, rows: [StatisticsRow], footer: StatisticsRow, columns: [KeyPath<StatisticsRow, String?>]) {
        self.header = header
        self.rows = rows
        self.footer = footer
        self.columns = columns

        self.verticalSeparatorView = (0...columns.count).map({ _ in UIView() })
        self.headerRowView = StatisticsRowView(row: header, columns: columns)
        self.regularRowViews = rows.map({ StatisticsRowView(row: $0, columns: columns) })
        self.footerRowView = StatisticsRowView(row: footer, columns: columns)

        super.init(frame: .zero)

        self.backgroundColor = .white
        self.verticalSeparatorView.forEach({ $0.backgroundColor = .black })
        self.separatorView.backgroundColor = .black
        self.stackView.axis = .vertical
        self.stackView.distribution = .fill
        self.stackView.alignment = .fill
        self.stackView.spacing = 0

        self.verticalSeparatorView.forEach(self.addSubview(_:))
        self.addSubview(self.separatorView)
        self.addSubview(self.headerRowView)
        self.addSubview(self.stackView)
        self.addSubview(self.footerRowView)
        self.regularRowViews.forEach(self.stackView.addArrangedSubview(_:))
        self.regularRowViews.forEach(self.headerRowView.align(with:))
        self.footerRowView.align(with: self.headerRowView)

        for (index, separator) in self.verticalSeparatorView.enumerated() {
            separator.snp.makeConstraints({ make in
                if index == 0 { make.left.equalToSuperview() }
                else if index == self.columns.count { make.right.equalToSuperview() }
                else { make.centerX.equalTo(self.headerRowView.gap(at: index - 1)).offset(5) }
                make.top.bottom.equalToSuperview()
                make.width.equalTo(0.5)
            })
        }

        self.separatorView.snp.makeConstraints({ make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        })

        self.headerRowView.snp.makeConstraints({ make in
            make.top.equalTo(self.separatorView.snp.bottom)
            make.left.equalTo(self.verticalSeparatorView.first!.snp.right)
            make.right.equalTo(self.verticalSeparatorView.last!.snp.left)
        })

        self.stackView.snp.makeConstraints({ make in
            make.top.equalTo(self.headerRowView.snp.bottom)
            make.left.right.equalTo(self.headerRowView)
        })

        self.footerRowView.snp.makeConstraints({ make in
            make.top.equalTo(self.stackView.snp.bottom)
            make.left.right.equalTo(self.headerRowView)
            make.bottom.equalToSuperview()
        })
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

class StatisticsRowView: UIView {
    let columns: [KeyPath<StatisticsRow, String?>]
    var row: StatisticsRow {
        didSet { self.performFormattingUpdate() }
    }

    private let labels: [UILabel]
    private let separatorView = UIView()

    init(row: StatisticsRow, columns: [KeyPath<StatisticsRow, String?>]) {
        self.columns = columns
        self.row = row

        self.labels = (0..<columns.count).map({ _ in UILabel() })

        super.init(frame: .zero)

        self.separatorView.backgroundColor = .black

        self.labels.forEach(self.addSubview(_:))
        self.addSubview(self.separatorView)

        for label in self.labels {
            label.snp.makeConstraints { make in
                make.top.equalToSuperview()
            }
        }

        for label in self.labels.dropFirst() {
            label.snp.makeConstraints { make in
                make.top.bottom.equalTo(self.labels.first!)
            }
        }

        for (left, right) in zip(self.labels, self.labels.dropFirst()) {
            right.snp.makeConstraints { make in
                make.left.equalTo(left.snp.right).offset(10)
            }
        }

        self.labels.first!.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(5)
        }

        self.labels.last!.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(5)
        }

        self.separatorView.snp.makeConstraints { make in
            make.top.equalTo(self.labels.first!.snp.bottom)
            make.height.equalTo(0.5)
            make.left.right.bottom.equalToSuperview()
        }

        self.performFormattingUpdate()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func align(with other: StatisticsRowView) {
        for (first, second) in zip(self.labels, other.labels) {
            first.widthAnchor.constraint(equalTo: second.widthAnchor).isActive = true
        }
    }

    func gap(at index: Int) -> ConstraintItem {
        return self.labels[index].snp.right
    }

    private func performFormattingUpdate() {
        self.backgroundColor = self.row.backgroundColor?.withAlphaComponent(0.2)

        for (label, column) in zip(self.labels, self.columns) {
            label.text = self.row[keyPath: column]
        }
    }
}
