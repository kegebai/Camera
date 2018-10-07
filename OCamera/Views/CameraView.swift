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
    private var viewModel: CameraViewModel!
    
    lazy var previewView: PreviewView = {
        let view: PreviewView = PreviewView(frame: self.bounds)
        view.delegate = self
        return view
    }()
    
    lazy var overlayView: OverlayView = {
        let view: OverlayView = OverlayView(frame: self.bounds)
        view.statusBar.flashControl.addTarget(self,
                                              action: #selector(flashControlChange(_:)),
                                              for: .touchUpInside)
        view.statusBar.swapCameraButton.addTarget(self,
                                                  action: #selector(swapCameras(_:)),
                                                  for: .touchUpInside)
        view.modeBar.captureButton.addTarget(self,
                                             action: #selector(takePhotoOrVideo(_:)),
                                             for: .touchUpInside)
        view.modeBar.addTarget(self,
                               action: #selector(cameraModeChanged(_:)),
                               for: .valueChanged)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black
        
        self.addSubview(self.previewView)
        self.addSubview(self.overlayView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CameraView {
    func bind(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        self.previewView.session       = self.viewModel.cameraService.captureSession
        self.previewView.exposeEnabled = self.viewModel.cameraService.cameraSupportExpose
        self.previewView.focusEnabled  = self.viewModel.cameraService.cameraSupportFocus
        
        self.overlayView.statusBar.elapsedTimeLabel.text = self.viewModel.updateTimeDisplay()
        self.overlayView.modeBar.thumbnail = self.viewModel.updateThumbnail()
    }
}

extension CameraView: PreviewViewDelegate {

    func tappedFocusAt(point: CGPoint) {
        self.viewModel.cameraService.focusAt(point: point)
    }

    func tappedExposeAt(point: CGPoint) {
        self.viewModel.cameraService.exposeAt(point: point)
    }

    func tappedReset() {
        self.viewModel.cameraService.resetModes()
    }
}

extension CameraView {
    
    @objc private func flashControlChange(_ sender: FlashControl) {
        let mode: Int = sender.selectedMode
        if (self.viewModel.cameraMode == .photo) {
            self.viewModel.cameraService.flashMode = AVCaptureDevice.FlashMode(rawValue: mode)!
        } else {
            self.viewModel.cameraService.torchMode = AVCaptureDevice.TorchMode(rawValue: mode)!
        }
    }
    
    @objc private func swapCameras(_ sender: Any) {
        if (self.viewModel.cameraService.canSwitchCamera()) {
            self.overlayView.flashControlIsHidden =
                self.viewModel.cameraMode == .photo ?
                    !self.viewModel.cameraService.cameraHasFlash : !self.viewModel.cameraService.cameraHasTorch
            
            self.previewView.focusEnabled  = self.viewModel.cameraService.cameraSupportFocus
            self.previewView.exposeEnabled = self.viewModel.cameraService.cameraSupportExpose
            self.viewModel.cameraService.resetModes()
        }
    }
    
    @objc private func takePhotoOrVideo(_ sender: UIButton) {
        if (self.viewModel.cameraMode == .photo) {
            self.viewModel.cameraService.captureStillImage()
        } else {
            if (!self.viewModel.cameraService.isRecording) {
                DispatchQueue.global().async {
                    self.viewModel.cameraService.startRecording()
                    self.viewModel.startTimer()
                }
            } else {
                self.viewModel.cameraService.stopRecording()
                self.viewModel.stopTimer()
            }
        }
        sender.isSelected = !sender.isSelected
    }
    
    @objc private func cameraModeChanged(_ sender: CameraModeView) {
        guard self.viewModel != nil else { return }
        
        self.viewModel.cameraMode = sender.cameraMode
    }
}
