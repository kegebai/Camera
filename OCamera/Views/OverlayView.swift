//
//  OverlayView.swift
//  OCamera
//
//  Created by kegebai on 2018/9/23.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit

class OverlayView: UIView {
    
    var flashControlIsHidden: Bool = true {
        willSet { self.statusBar.flashControl.isHidden = newValue }
    }
    
    lazy var modeBar: CameraModeView = {
        let mode: CameraModeView = CameraModeView(frame: CGRect(x: 0,
                                                                y: self.bounds.maxY-110,
                                                            width: self.width,
                                                           height: 110))
        mode.addTarget(self, action: #selector(modeChanged(_:)), for: .valueChanged)
        return mode
    }()
    
    lazy var statusBar: StatusView = {
        let status: StatusView = StatusView(frame: CGRect(x: 0,
                                                          y: 0,
                                                      width: self.width,
                                                     height: 48))
        return status
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        
        self.addSubview(self.modeBar)
        self.addSubview(self.statusBar)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard self.modeBar.point(inside: self.convert(point, to: self.modeBar), with: event) ||
            self.statusBar.point(inside: self.convert(point, to: self.statusBar), with: event) else {
                return false
        }
        return true
    }
}

extension OverlayView {
    
    @objc private func modeChanged(_ sender: CameraModeView) {
        let photoEnabled: Bool = sender.cameraMode == .photo
        let toColor: UIColor   = photoEnabled ? .black : UIColor(white: 0.0, alpha: 0.5)
        let toOpacity: CGFloat = photoEnabled ? 0.0 : 1.0
        self.statusBar.layer.backgroundColor = toColor.cgColor
        self.statusBar.elapsedTimeLabel.layer.opacity = Float(toOpacity)
    }
}
