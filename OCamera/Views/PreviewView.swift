//
//  PreviewView.swift
//  OCamera
//
//  Created by kegebai on 2018/9/23.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

@objc protocol PreviewViewDelegate {
    func tappedFocusAt(point: CGPoint)
    func tappedExposeAt(point: CGPoint)
    func tappedReset()
}

let BOX_FRAME   : CGRect  = CGRect(x: 0, y: 0, width: 150, height: 150)
let FOCUS_COLOR : UIColor = UIColor(red: 0.102, green: 0.636, blue: 1.000, alpha: 1.000)
let EXPOSE_COLOR: UIColor = UIColor(red: 1.000, green: 0.421, blue: 0.054, alpha: 1.000)

class PreviewView: UIView {
    weak var delegate: PreviewViewDelegate?
    
    var focusEnabled: Bool = false {
        willSet { self.click.isEnabled = newValue }
    }
    
    var exposeEnabled: Bool = false {
        willSet { self.doubleClick.isEnabled = newValue }
    }
    
    var session: AVCaptureSession {
        set { self.previewLayer.session = newValue }
        get { return self.previewLayer.session! }
    }
    
    private var focusBox : UIView!
    private var exposeBox: UIView!
    
    private var click         : UITapGestureRecognizer! // one finger click
    private var doubleClick   : UITapGestureRecognizer! // one finger double click
    private var twoDoubleClick: UITapGestureRecognizer! // two fingers double click
    
    private var previewLayer: AVCaptureVideoPreviewLayer {
        return (self.layer as! AVCaptureVideoPreviewLayer)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

extension PreviewView {
    
    private func setUp() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.click          = UITapGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        self.doubleClick    = UITapGestureRecognizer(target: self, action: #selector(handleDoubleClick(_:)))
        self.twoDoubleClick = UITapGestureRecognizer(target: self, action: #selector(handleTwoDoubleClick(_:)))
        self.doubleClick.numberOfTapsRequired = 2
        self.twoDoubleClick.numberOfTouchesRequired = 2
        self.twoDoubleClick.numberOfTapsRequired = 2
        self.click.require(toFail: self.doubleClick)
        
        self.addGestureRecognizer(self.click)
        self.addGestureRecognizer(self.doubleClick)
        self.addGestureRecognizer(self.twoDoubleClick)
        
        self.focusBox  = self.viewWith(color: FOCUS_COLOR)
        self.exposeBox = self.viewWith(color: EXPOSE_COLOR)
        self.addSubview(self.focusBox)
        self.addSubview(self.exposeBox)
    }
    
    private func viewWith(color: UIColor) -> UIView {
        let view: UIView = UIView(frame: BOX_FRAME)
        view.backgroundColor   = .clear
        view.isHidden          = true
        view.layer.borderColor = color.cgColor
        view.layer.borderWidth = 5.0
        return view
    }
    
    private func boxAnimation(on view: UIView, point: CGPoint) {
        view.center   = point
        view.isHidden = false
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
        }) { (finished) in
            let delayInSeconds = 0.5
            let popTime: DispatchTime = DispatchTime(uptimeNanoseconds: UInt64(delayInSeconds) * NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
                view.isHidden  = true
                view.transform = CGAffineTransform.identity
            })
        }
    }
    
    private func resetAnimation() {
        guard self.focusEnabled && self.exposeEnabled else { return }
        
        let centerPoint: CGPoint = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: 0.5, y: 0.5))
        self.focusBox.isHidden   = false
        self.focusBox.center     = centerPoint
        self.exposeBox.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        self.exposeBox.isHidden  = false
        self.exposeBox.center    = centerPoint
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            self.focusBox.layer.transform  = CATransform3DMakeScale(0.5, 0.5, 1.0)
            self.exposeBox.layer.transform = CATransform3DMakeScale(0.7, 0.7, 1.0)
        }) { (finished) in
            let delayInSeconds = 0.5
            let popTime: DispatchTime = DispatchTime(uptimeNanoseconds: UInt64(delayInSeconds) * NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
                self.focusBox.transform  = CGAffineTransform.identity
                self.focusBox.isHidden   = true
                self.exposeBox.transform = CGAffineTransform.identity
                self.exposeBox.isHidden  = true
            })
        }
    }
    
    private func captureDevicePointOf(point: CGPoint) -> CGPoint {
        return self.previewLayer.captureDevicePointConverted(fromLayerPoint: point)
    }
}

extension PreviewView {
    
    @objc private func handleClick(_ gestureRecognizer: UITapGestureRecognizer) {
        let point: CGPoint = gestureRecognizer.location(in: self)
        self.boxAnimation(on: self.focusBox, point: point)
        
        self.delegate?.tappedFocusAt(point: self.captureDevicePointOf(point: point))
    }
    
    @objc private func handleDoubleClick(_ gestureRecognizer: UITapGestureRecognizer) {
        let point: CGPoint = gestureRecognizer.location(in: self)
        self.boxAnimation(on: self.exposeBox, point: point)
        
        self.delegate?.tappedExposeAt(point: self.captureDevicePointOf(point: point))
    }
    
    @objc private func handleTwoDoubleClick(_ gestureRecognizer: UITapGestureRecognizer) {
        self.resetAnimation()
        
        self.delegate?.tappedReset()
    }
}
