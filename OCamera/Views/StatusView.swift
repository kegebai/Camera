//
//  StatusView.swift
//  OCamera
//
//  Created by kegebai on 2018/9/23.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit

class StatusView: UIView {
    
    lazy var flashControl: FlashControl = {
        let flash: FlashControl = FlashControl()
        flash.delegate = self
        return flash
    }()
    
    lazy var elapsedTimeLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect(x: 100,
                                                   y: 11,
                                               width: self.width-100*2,
                                              height: 26))
        label.font = UIFont.systemFont(ofSize: 19)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    lazy var swapCameraButton: UIButton = {
        let button: UIButton = UIButton(frame: CGRect(x: self.width-36,
                                                      y: 14,
                                                  width: 20,
                                                 height: 20))
        button.setImage(UIImage(named: "camera"), for: .normal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        
        self.addSubview(self.flashControl)
        self.addSubview(self.elapsedTimeLabel)
        self.addSubview(self.swapCameraButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StatusView: FlashControlDelegate {
    
    func flashControlWillExpand() {
        UIView.animate(withDuration: 0.2) { self.elapsedTimeLabel.alpha = 0.0 }
    }
    
    func flashControlDidCollapse() {
        UIView.animate(withDuration: 0.1) { self.elapsedTimeLabel.alpha = 1.0 }
    }
}
