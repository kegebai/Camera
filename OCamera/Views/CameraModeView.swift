//
//  CameraModeView.swift
//  OCamera
//
//  Created by kegebai on 2018/9/23.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
import CoreServices

class CameraModeView: UIControl {
    
    var captureButton: CaptureButton = CaptureButton.captureButton()
    var thumbnailButton: UIButton!
    var thumbnail: UIImage? {
        willSet {
            self.thumbnailButton.setImage(newValue, for: .normal)
            self.thumbnailButton.layer.borderColor = UIColor.white.cgColor
            self.thumbnailButton.layer.borderWidth = 1.0
        }
    }
    
    var cameraMode: CameraMode = .photo {
        willSet {
            if (newValue == .photo) {
                self.layer.backgroundColor = UIColor.black.cgColor
                self.captureButton.captureMode = .photo
                self.captureButton.isSelected  = false
            } else {
                self.layer.backgroundColor = UIColor(white: 0.5, alpha: 0.5).cgColor
                self.captureButton.captureMode = .video
                //self.captureButton.isSelected  = true
            }
        }
        didSet {
            self.sendActions(for: .valueChanged)
        }
    }
    
    private var foregroundColor: UIColor = UIColor(red: 1.000, green: 0.734, blue: 0.006, alpha: 1.0)
    private var containerView  : UIView  = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
    private var videoTextLayer : CATextLayer = CATextLayer()
    private var photoTextLayer : CATextLayer = CATextLayer()
    
    private var maxLeft : Bool = false
    private var maxRight: Bool = true
    
    private var videoTextWidth: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.containerView.x = self.bounds.midX - self.videoTextWidth / 2.0
    }
    
    override func draw(_ rect: CGRect) {
        //super.draw(rect)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(self.foregroundColor.cgColor)
        context.fillEllipse(in: CGRect(x: self.bounds.midX-4.0, y: 2.0, width: 6.0, height: 6.0))
    }
}

extension CameraModeView {
    
    @objc private func switchMode(_ gestureRecognizer: UISwipeGestureRecognizer) {
        if (gestureRecognizer.direction == .left && !self.maxLeft) {
            
            UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseInOut, animations: {
                self.containerView.x -= 62
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveLinear, animations: {
                    CATransaction.disableActions()
                    self.photoTextLayer.foregroundColor = self.foregroundColor.cgColor
                    self.videoTextLayer.foregroundColor = UIColor.white.cgColor
                }, completion: { (isFinished) in
                    
                })
            }) { (finished) in
                self.cameraMode = .photo
                self.maxLeft    = true
                self.maxRight   = false
            }
        }
        else if (gestureRecognizer.direction == .right && !self.maxRight) {
            
            UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseInOut, animations: {
                self.containerView.x += 62
                self.videoTextLayer.foregroundColor = self.foregroundColor.cgColor
                self.photoTextLayer.foregroundColor = UIColor.white.cgColor
            }) { (finished) in
                self.cameraMode = .video
                self.maxLeft    = false
                self.maxRight   = true
            }
        }
    }
}

extension CameraModeView {
    
    private func setUp() {
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        self.cameraMode = .video
        
        self.captureButton.frame = CGRect(x: self.centerX-34, y: 36, width: 68, height: 68)
        self.thumbnailButton = UIButton(frame: CGRect(x: 40, y: 45, width: 45, height: 45))
        //self.thumbnailButton.addTarget(self, action: #selector(openCameraRoll(_:)), for: .touchUpOutside)
        self.addSubview(self.captureButton)
        self.addSubview(self.thumbnailButton)
        
        let videoText: String = "VIDEO"
        let size: CGSize = (videoText as NSString).size(withAttributes: self.attributes())
        self.videoTextWidth = size.width
        
        self.videoTextLayer = self.layerWith(title: videoText)
        self.photoTextLayer = self.layerWith(title: "PHOTO")
        self.videoTextLayer.foregroundColor = self.foregroundColor.cgColor
        self.videoTextLayer.frame = CGRect(x: 0,  y: 0, width: 40, height: 20)
        self.photoTextLayer.frame = CGRect(x: 60, y: 0, width: 50, height: 20)
        
        self.containerView.layer.addSublayer(self.videoTextLayer)
        self.containerView.layer.addSublayer(self.photoTextLayer)
        self.containerView.backgroundColor = .clear
        
        self.addSubview(self.containerView)
        self.containerView.centerY += 8.0
        
        let rightSwipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(switchMode(_:)))
        let leftSwipe : UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(switchMode(_:)))
        leftSwipe.direction = .left
        self.addGestureRecognizer(rightSwipe)
        self.addGestureRecognizer(leftSwipe)
    }

    private func layerWith(title: String) -> CATextLayer {
        let layer: CATextLayer = CATextLayer()
        layer.string = NSAttributedString(string: title, attributes: self.attributes())
        layer.contentsScale = UIScreen.main.scale
        return layer
    }
    
    private func attributes() -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont(name: "AvenirNextCondensed-DemiBold", size: 17.0) as Any,
            .foregroundColor: UIColor.white
        ]
    }
    
    private func toggleSelected() {
        self.captureButton.isSelected = !self.captureButton.isSelected
    }
}
