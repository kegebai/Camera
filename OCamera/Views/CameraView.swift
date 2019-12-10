//
//  CameraView.swift
//  OCamera
//
//  Created by kegebai on 2018/9/23.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CameraView: UIView {
    private var cameraMode: CameraMode = .video
    private var cameraService: CameraService!
    private var timer: Timer!
    
    lazy var previewView: PreviewView = {
        let view: PreviewView = PreviewView(frame: self.bounds)
        view.delegate = self
        return view
    }()
    
    lazy var overlayView: OverlayView = {
        let view: OverlayView = OverlayView(frame: self.bounds)
        view.statusBar.flashControl.addTarget(self, action: #selector(flashControlChange(_:)), for: .touchUpInside)
        view.statusBar.swapCameraButton.addTarget(self, action: #selector(swapCameras(_:)), for: .touchUpInside)
        view.modeBar.captureButton.addTarget(self, action: #selector(takePhotoOrVideo(_:)), for: .touchUpInside)
        view.modeBar.addTarget(self, action: #selector(cameraModeChanged(_:)), for: .valueChanged)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black
        
        NotificationCenter.observe(self, notification: .GeneraterThumbnail, selector: #selector(generateThumbnail(_:)))
        
        self.addSubview(self.previewView)
        self.addSubview(self.overlayView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CameraView {
    func bind(service: CameraService) {
        self.cameraService = service
        self.cameraService.detectionFaceDelegate = self.previewView
        self.previewView.session       = self.cameraService.captureSession
        self.previewView.exposeEnabled = self.cameraService.cameraSupportExpose
        self.previewView.focusEnabled  = self.cameraService.cameraSupportFocus
    }
}

extension CameraView: PreviewViewDelegate {

    func tappedFocusAt(point: CGPoint) {
        try! self.cameraService.focusAt(point: point)
    }

    func tappedExposeAt(point: CGPoint) {
        try! self.cameraService.exposeAt(point: point)
    }

    func tappedReset() {
        try! self.cameraService.resetModes()
    }
}

extension CameraView {
    
    @objc private func flashControlChange(_ sender: FlashControl) {
        let mode: Int = sender.selectedMode
        if (self.cameraMode == .photo) {
            self.cameraService.flashMode = AVCaptureDevice.FlashMode(rawValue: mode)!
        } else {
            self.cameraService.torchMode = AVCaptureDevice.TorchMode(rawValue: mode)!
        }
    }
    
    @objc private func swapCameras(_ sender: Any) {
        if (self.cameraService.switchCamera()) {
            var hidden = false
            hidden = self.cameraMode == .photo ? !self.cameraService.cameraHasFlash : !self.cameraService.cameraHasTorch
            self.overlayView.flashControlIsHidden = hidden
            self.previewView.focusEnabled  = self.cameraService.cameraSupportFocus
            self.previewView.exposeEnabled = self.cameraService.cameraSupportExpose
            try! self.cameraService.resetModes()
        }
    }
    
    @objc private func takePhotoOrVideo(_ sender: CaptureButton) {
        if (self.cameraMode == .photo) {
            self.cameraService.captureStillImage()
        } else {
            if (!self.cameraService.isRecording) {
                DispatchQueue(label: "com.ocamera").async {
                    try! self.cameraService.startRecording()
                }
                self.startTimer()
            } else {
                self.cameraService.stopRecording()
                self.stopTimer()
            }
        }
        sender.isSelected = !sender.isSelected
    }
    
    @objc private func cameraModeChanged(_ sender: CameraModeView) {
        guard self.cameraService != nil else { return }
        self.cameraMode = sender.cameraMode
    }
    
    @objc private func generateThumbnail(_ noti: Notification) {
        self.overlayView.modeBar.thumbnailButton.setImage(noti.object as? UIImage, for: .normal)
    }
}

extension CameraView {
    
    private func startTimer() {
        self.timer = Timer(timeInterval: 0.5,
                           target: self,
                           selector: #selector(updateTimeDisplay),
                           userInfo: nil,
                           repeats: true)
        RunLoop.current.add(self.timer, forMode: .common)
    }
    
    private func stopTimer() {
        self.timer.invalidate()
        self.timer = nil
        self.overlayView.statusBar.elapsedTimeLabel.text = "00:00:00"
    }
    
    @objc private func updateTimeDisplay() {
        let duration: CMTime = self.cameraService.recordedDuration()
        let time   : Int = Int(CMTimeGetSeconds(duration))
        let hours  : Int = time / 3600
        let minutes: Int = (time / 60) % 60
        let seconds: Int = time % 60
        
        let fmt: String = "%02i:%02i:%02i"
        let tempString: String = String(format: fmt, hours, minutes, seconds)
        
        self.overlayView.statusBar.elapsedTimeLabel.text = tempString
    }
}
