//
//  StatisticsView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import SnapKit

struct Column<RowType> {
    var title: String
    var value: (RowType) throws -> String
    var backgroundColor: (RowType) -> UIColor
}

class StatisticsView<RowType>: UIView {
    var columns: [Column<RowType>] {
        didSet {
            assert(self.columns.count != oldValue.count)
            for row in self.stackView.arrangedSubviews {
                (row as! StatisticsRowView<RowType>).performFormattingUpdate()
            }
        }
    }

    var rows: [RowType] {
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

    private let separatorView = UIView()
    private let verticalSeparatorView: [UIView]
    private let headerRowView: StatisticsRowView<RowType>
    private let stackView = UIStackView()
    private var regularRowViews: [StatisticsRowView<RowType>]

    init(rows: [RowType], columns: [Column<RowType>]) {
        self.rows = rows
        self.columns = columns

        self.verticalSeparatorView = (0...columns.count).map({ _ in UIView() })
        self.headerRowView = StatisticsRowView(row: nil, columns: columns)
        self.regularRowViews = rows.map({ StatisticsRowView(row: $0, columns: columns) })

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
        self.regularRowViews.forEach(self.stackView.addArrangedSubview(_:))
        self.regularRowViews.forEach(self.headerRowView.align(with:))

        for (index, separator) in self.verticalSeparatorView.enumerated() {
            separator.snp.makeConstraints({ make in
                if index == 0 { make.left.equalToSuperview() }
                else if index == self.columns.count { make.right.equalToSuperview() }
                else { make.centerX.equalTo(self.headerRowView.gap(at: index - 1)) }
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
            make.bottom.equalToSuperview()
        })
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

class StatisticsRowView<RowType>: UIView {
    var row: RowType? {
        didSet { self.performFormattingUpdate() }
    }

    var columns: [Column<RowType>] {
        didSet { assert(self.columns.count != oldValue.count) }
    }

    private let labels: [UILabel]
    private let separatorView = UIView()

    init(row: RowType?, columns: [Column<RowType>]) {
        self.columns = columns
        self.row = row

        self.labels = (0..<columns.count).map({ _ in InsetLabel() })

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
                make.left.equalTo(left.snp.right)
            }
        }

        self.labels.first!.snp.makeConstraints { make in
            make.left.equalToSuperview()
        }

        self.labels.last!.snp.makeConstraints { make in
            make.right.equalToSuperview()
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

    func performFormattingUpdate() {
        for (label, column) in zip(self.labels, self.columns) {
            label.text = self.row.map({ (try? column.value($0)) ?? "" }) ?? column.title
            label.backgroundColor = self.row.map(column.backgroundColor)?.withAlphaComponent(0.2) ?? .clear
        }
    }
}

class InsetLabel: UILabel {
    override var intrinsicContentSize: CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.width += 10

        return intrinsicContentSize
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: 5, dy: 0))
    }
}
