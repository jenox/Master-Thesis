//
//  UIViewHostingView.swift
//  MasterThesis
//
//  Created by Christian Schnorr on 27.03.20.
//  Copyright © 2020 Christian Schnorr. All rights reserved.
//

import UIKit

class UIViewHostingView<ContentView>: UIView where ContentView: UIView {
    let contentView: ContentView

    init(contentView: ContentView) {
        self.contentView = contentView
        super.init(frame: contentView.bounds)
        self.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.setContentHuggingPriority(.required, for: .horizontal)
        self.setContentHuggingPriority(.required, for: .vertical)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override var intrinsicContentSize: CGSize {
        return contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}
