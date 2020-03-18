//
//  FloatSettingView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 18.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit
import SnapKit

class FloatSettingView: UIView {
    private let textLabel = UILabel()
    private let slider = UISlider()
    private let toggle = UISwitch()

    var valueChanged: (() -> Void)? = nil

    var value: CGFloat {
        return self.toggle.isOn ? CGFloat(exp(self.slider.value)) : 0
    }

    init(title: String, value: CGFloat, range: ClosedRange<CGFloat>) {
        super.init(frame: .zero)

        self.textLabel.text = title
        self.slider.minimumValue = Float(log(range.lowerBound))
        self.slider.maximumValue = Float(log(range.upperBound))
        self.slider.value = Float(log(value))
        self.toggle.isOn = true

        self.addSubview(self.textLabel)
        self.addSubview(self.slider)
        self.addSubview(self.toggle)
        self.slider.addTarget(self, action: #selector(self.sliderDidChange), for: .valueChanged)
        self.toggle.addTarget(self, action: #selector(self.toggleDidChange), for: .valueChanged)

        self.textLabel.snp.makeConstraints({ make in
            make.top.left.bottom.equalToSuperview()
        })

        self.slider.snp.makeConstraints({ make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(self.textLabel.snp.right).offset(10)
            make.width.equalTo(200)
        })

        self.toggle.snp.makeConstraints({ make in
            make.left.equalTo(self.slider.snp.right).offset(10)
            make.top.right.bottom.equalToSuperview()
        })
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    @objc private func sliderDidChange() {
        self.valueChanged?()
    }

    @objc private func toggleDidChange() {
        self.valueChanged?()
        self.slider.isEnabled = self.toggle.isOn
    }
}
