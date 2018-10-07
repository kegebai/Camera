//
//  CaptureButton.swift
//  OCamera
//
//  Created by kegebai on 2018/9/21.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit

let DEFAULT_FRAME = CGRect(x: 0.0, y: 0.0, width: 68.0, height: 68.0)
let LINE_WIDTH: CGFloat = 6.0

class CaptureButton: UIButton {
    
    var captureMode: CameraMode = .photo {
        willSet {
            let toColor: UIColor = newValue == .video ? .red : .white
            self.circleLayer.backgroundColor = toColor.cgColor
        }
    }
    
    private var circleLayer: CALayer = CALayer()
    
    convenience init(withMode: CameraMode? = .video) {
        self.init(frame: DEFAULT_FRAME)
        
        self.setUp()
    }
        
    override func draw(_ rect: CGRect) {
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(UIColor.white.cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.setLineWidth(LINE_WIDTH)
        
        let inRect: CGRect = rect.insetBy(dx: LINE_WIDTH/2.0, dy: LINE_WIDTH/2.0)
        context.strokeEllipse(in: inRect)
    }
    
    override var isHighlighted: Bool {
        willSet {
            let fadeAnimation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.duration              = 0.2
            fadeAnimation.timingFunction        = CAMediaTimingFunction(name: .easeOut)
            fadeAnimation.toValue               = newValue ? 0.0 : 1.0
            self.circleLayer.opacity            = fadeAnimation.toValue as! Float
            self.circleLayer.add(fadeAnimation, forKey: "fadeAnimation")
        }
    }
    
    override var isSelected: Bool {
        willSet {
            if (self.captureMode == .video) {
                CATransaction.disableActions()
                let scaleAnimation : CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
                let radiusAnimation: CABasicAnimation = CABasicAnimation(keyPath: "cornerRadius")

                if (newValue) {
                    scaleAnimation.toValue  = 0.6
                    radiusAnimation.toValue = self.circleLayer.bounds.width / 4.0
                } else {
                    scaleAnimation.toValue  = 1.0
                    radiusAnimation.toValue = self.circleLayer.bounds.width / 2.0
                }

                let animationGroup: CAAnimationGroup = CAAnimationGroup()
                animationGroup.animations = [scaleAnimation, radiusAnimation]
                animationGroup.beginTime  = CACurrentMediaTime() + 0.2
                animationGroup.duration   = 0.35

                self.circleLayer.setValue(scaleAnimation.toValue,  forKey: "transform.scale")
                self.circleLayer.setValue(radiusAnimation.toValue, forKey: "cornerRadius")
                self.circleLayer.add(animationGroup, forKey: "scaleAndRadiusAnimation")
            }
        }
    }
}

extension CaptureButton {
    static func captureButton() -> CaptureButton {
        //return self.captureButtonWithMode(.photo)
        return CaptureButton()
    }
    
    class func captureButtonWithMode(_ mode: CameraMode) -> CaptureButton {
        return CaptureButton(withMode: mode)
    }
}

extension CaptureButton {
    
    private func setUp() {
        self.captureMode              = .video
        self.backgroundColor          = .clear
        self.tintColor                = .clear
        let circleColor: UIColor      = self.captureMode == .video ? .red : .white
        self.circleLayer.backgroundColor = circleColor.cgColor
        self.circleLayer.bounds       = self.bounds.insetBy(dx: 8.0, dy: 8.0)
        self.circleLayer.cornerRadius = self.circleLayer.bounds.width / 2.0
        self.circleLayer.position     = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        self.layer.addSublayer(self.circleLayer)
    }
}
