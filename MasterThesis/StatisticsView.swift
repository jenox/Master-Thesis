//
//  StatisticsView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 08.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit

struct CountryStatistics {
    var countryName: String
    var countryColor: UIColor
    var statisticalAccuracy: Double
    var localFatness: Double
}

class StatisticsView: UIView {
    var countryStatistics: [CountryStatistics] {
        didSet {
            stackView.arrangedSubviews.dropFirst(countryStatistics.count).forEach({
                stackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            })

            for x in countryStatistics.dropFirst(stackView.arrangedSubviews.count) {
                let view = CountryStatisticsView(countryStatistics: x)
                stackView.addArrangedSubview(view)
                NSLayoutConstraint.activate([
                    view.countryNameLabel.widthAnchor.constraint(equalTo: countryNameSummaryLabel.widthAnchor),
                    view.statisticalAccuracyLabel.widthAnchor.constraint(equalTo: statisticalAccuracyCaptionLabel.widthAnchor),
                    view.localFatnessLabel.widthAnchor.constraint(equalTo: localFatnessCaptionLabel.widthAnchor)
                ])
            }

            for (view, stats) in zip(stackView.arrangedSubviews, countryStatistics) {
                (view as! CountryStatisticsView).countryStatistics = stats
            }
        }
    }

    private let countryNameCaptionLabel = UILabel()
    private let statisticalAccuracyCaptionLabel = UILabel()
    private let localFatnessCaptionLabel = UILabel()
    private let separatorView = UIView()
    private let stackView = UIStackView()
    private let countryNameSummaryLabel = UILabel()
    private let statisticalAccuracySummaryLabel = UILabel()
    private let localFatnessSummaryLabel = UILabel()
    private let verticalSeparatorView1 = UIView()
    private let verticalSeparatorView2 = UIView()

    init(countryStatistics: [CountryStatistics]) {
        self.countryStatistics = countryStatistics

        super.init(frame: .zero)

        addSubview(countryNameCaptionLabel)
        addSubview(statisticalAccuracyCaptionLabel)
        addSubview(localFatnessCaptionLabel)
        addSubview(separatorView)
        addSubview(stackView)
        addSubview(countryNameSummaryLabel)
        addSubview(statisticalAccuracySummaryLabel)
        addSubview(localFatnessSummaryLabel)
        addSubview(verticalSeparatorView1)
        addSubview(verticalSeparatorView2)

        countryNameCaptionLabel.text = "Country"
        statisticalAccuracyCaptionLabel.text = "Statistical Accuary"
        localFatnessCaptionLabel.text = "Local Fattness"
        countryNameSummaryLabel.text = "Total"
        statisticalAccuracySummaryLabel.text = "100%"
        localFatnessSummaryLabel.text = "100%"
        separatorView.backgroundColor = UIColor.black
        verticalSeparatorView1.backgroundColor = UIColor.black
        verticalSeparatorView2.backgroundColor = UIColor.black

        for x in countryStatistics {
            let view = CountryStatisticsView(countryStatistics: x)
            stackView.addArrangedSubview(view)
            NSLayoutConstraint.activate([
                view.countryNameLabel.widthAnchor.constraint(equalTo: countryNameSummaryLabel.widthAnchor),
                view.statisticalAccuracyLabel.widthAnchor.constraint(equalTo: statisticalAccuracyCaptionLabel.widthAnchor),
                view.localFatnessLabel.widthAnchor.constraint(equalTo: localFatnessCaptionLabel.widthAnchor)
            ])
        }

        backgroundColor = .white
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0

        countryNameCaptionLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
        }
        statisticalAccuracyCaptionLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(countryNameCaptionLabel)
            make.left.equalTo(countryNameCaptionLabel.snp.right).offset(10)
        }
        localFatnessCaptionLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(countryNameCaptionLabel)
            make.left.equalTo(statisticalAccuracyCaptionLabel.snp.right).offset(10)
            make.right.equalToSuperview()
        }
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(countryNameCaptionLabel.snp.bottom)
            make.height.equalTo(0.5)
            make.left.right.equalToSuperview()
        }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom)
            make.left.right.equalToSuperview()
        }
        countryNameSummaryLabel.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom)
            make.width.equalTo(countryNameCaptionLabel)
            make.left.bottom.equalToSuperview()
        }
        statisticalAccuracySummaryLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(countryNameSummaryLabel)
            make.width.equalTo(statisticalAccuracyCaptionLabel)
            make.left.equalTo(countryNameCaptionLabel.snp.right).offset(10)
        }
        localFatnessSummaryLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(countryNameSummaryLabel)
            make.width.equalTo(localFatnessCaptionLabel)
            make.left.equalTo(statisticalAccuracyCaptionLabel.snp.right).offset(10)
            make.right.equalToSuperview()
        }

        verticalSeparatorView1.snp.makeConstraints { make in
            make.left.equalTo(countryNameCaptionLabel.snp.right).offset(5)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(0.5)
        }

        verticalSeparatorView2.snp.makeConstraints { make in
            make.left.equalTo(statisticalAccuracyCaptionLabel.snp.right).offset(5)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

class CountryStatisticsView: UIView {
    var countryStatistics: CountryStatistics {
        didSet { performFormattingUpdate() }
    }

    let countryNameLabel = UILabel()
    let statisticalAccuracyLabel = UILabel()
    let localFatnessLabel = UILabel()
    private let separatorView = UIView()

    init(countryStatistics: CountryStatistics) {
        self.countryStatistics = countryStatistics

        super.init(frame: .zero)

        addSubview(countryNameLabel)
        addSubview(statisticalAccuracyLabel)
        addSubview(localFatnessLabel)
        addSubview(separatorView)

        countryNameLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
        }
        statisticalAccuracyLabel.snp.makeConstraints { make in
            make.left.equalTo(countryNameLabel.snp.right).offset(10)
            make.top.bottom.equalTo(countryNameLabel)
        }
        localFatnessLabel.snp.makeConstraints { make in
            make.left.equalTo(statisticalAccuracyLabel.snp.right).offset(10)
            make.right.equalToSuperview()
            make.top.bottom.equalTo(countryNameLabel)
        }
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(countryNameLabel.snp.bottom)
            make.height.equalTo(0.5)
            make.left.right.bottom.equalToSuperview()
        }

        performFormattingUpdate()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func align(with other: CountryStatisticsView) {
        NSLayoutConstraint.activate([
            self.countryNameLabel.widthAnchor.constraint(equalTo: other.countryNameLabel.widthAnchor),
            self.statisticalAccuracyLabel.widthAnchor.constraint(equalTo: other.statisticalAccuracyLabel.widthAnchor),
            self.localFatnessLabel.widthAnchor.constraint(equalTo: other.localFatnessLabel.widthAnchor)
        ])
    }

    private func performFormattingUpdate() {
        separatorView.backgroundColor = UIColor.black
        backgroundColor = countryStatistics.countryColor.withAlphaComponent(0.2)
        countryNameLabel.text = "\(countryStatistics.countryName)"
        statisticalAccuracyLabel.text = "\(countryStatistics.statisticalAccuracy)"
        localFatnessLabel.text = "\(countryStatistics.localFatness)"
    }
}
