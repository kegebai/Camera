//
//  CameraService.swift
//  OCamera
//
//  Created by kegebai on 2018/9/23.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import AssetsLibrary
import Photos

@objc protocol CameraServiceDelegate {
    func deviceConfigurationFailed() throws
    func mediaCaptureFailed() throws
    func assetLibraryWriteFailed() throws
}

// Define KVO keyPath for observing 'OCameraAdjustingExposureKeyPath' device property.
let OCameraAdjustingExposureKeyPath: String = "OCameraAdjustingExposureKeyPath"

class CameraService: NSObject {
    weak var delegate: CameraServiceDelegate?
    
    private(set) var captureSession: AVCaptureSession = AVCaptureSession()
    
    private var activeVideoInput: AVCaptureDeviceInput?
    
    var imageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    //var photoOutput: AVCapturePhotoOutput      = AVCapturePhotoOutput()
    var movieOutput: AVCaptureMovieFileOutput  = AVCaptureMovieFileOutput()
    
    private(set) var outputURL: URL? {
        set {}
        get {
            guard let dirPath: String = FileManager.temporaryDirectoryWithTemplateString("OCamera.xxx")
                else { return nil }
            return URL(fileURLWithPath: dirPath.appending("ocamera_movie.mov"))
        }
    }
    
    // MARK: - Camera Device Support
    private(set) var cameraCount: Int {
        set {}
        get {
            //return AVCaptureDevice.devices(for: .video).count
            return self.cameras(for: nil).count
        }
    }
    
    private(set) var cameraHasTorch: Bool {
        set {}
        get { return self.activeCamera().hasTorch }
    }
    
    private(set) var cameraHasFlash: Bool {
        set {}
        get { return self.activeCamera().hasFlash }
    }
    
    private(set) var cameraSupportExpose: Bool {
        set {}
        get { return self.activeCamera().isExposurePointOfInterestSupported }
    }
    
    private(set) var cameraSupportFocus : Bool {
        set {}
        get { return self.activeCamera().isFocusPointOfInterestSupported }
    }
    
    var torchMode: AVCaptureDevice.TorchMode {
        set {
            let device: AVCaptureDevice = self.activeCamera()
            if device.torchMode != torchMode && device.isTorchModeSupported(torchMode) {
                try? device.lockForConfiguration()
                device.torchMode = torchMode
                device.unlockForConfiguration()
            } else {
                try? self.delegate?.deviceConfigurationFailed()
            }
        }
        
        get { return self.activeCamera().torchMode }
    }
    
    var flashMode: AVCaptureDevice.FlashMode {
        set {
            let device: AVCaptureDevice = self.activeCamera()
            if device.flashMode != flashMode && device.isFlashModeSupported(flashMode) {
                try? device.lockForConfiguration()
                device.torchMode = torchMode
                device.unlockForConfiguration()
            } else {
                try? self.delegate?.deviceConfigurationFailed()
            }
        }
        
        get { return self.activeCamera().flashMode }
    }
    
    private(set) var isRecording: Bool {
        set {}
        get { return self.movieOutput.isRecording }
    }
    
    // MARK: - init
    override init() {
        super.init()
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        if keyPath == OCameraAdjustingExposureKeyPath {
            let device: AVCaptureDevice = AVCaptureDevice(uniqueID: object as! String)!
            
            if device.isAdjustingExposure && device.isExposureModeSupported(.locked) {
                device.removeObserver(self, forKeyPath: OCameraAdjustingExposureKeyPath, context: nil)
                
                DispatchQueue.main.async {
                    try? device.lockForConfiguration()
                    device.exposureMode = .locked
                    device.unlockForConfiguration()
                }
            } else {
                try? self.delegate?.deviceConfigurationFailed()
            }
        } else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
        }
    }
    
    // MARK: - Hooks
    func configurationSessionInputs() throws -> Bool {
        // Set up default camera device
        guard let videoDevice: AVCaptureDevice = self.cameras(for: .video).first,
            let videoInput: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            self.captureSession.canAddInput(videoInput)
            else { return false }
        
        self.captureSession.addInput(videoInput)
        self.activeVideoInput = videoInput
        
        // Setup default microphone
        guard let audioDevice: AVCaptureDevice = self.cameras(for: .audio).first,
            let audioInput: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
            self.captureSession.canAddInput(audioInput)
            else { return false }
        
        self.captureSession.addInput(audioInput)

        return true
    }

    func configurationSessionOutputs() throws -> Bool {
        // Setup the still image output
        self.imageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        guard self.captureSession.canAddOutput(self.imageOutput) else { return false }
        self.captureSession.addOutput(self.imageOutput)
        
        // Setup movie file output
        guard self.captureSession.canAddOutput(self.movieOutput) else { return false }
        self.captureSession.addOutput(self.movieOutput)
        
        return true
    }

    func sessionParent() -> AVCaptureSession.Preset { return .high }
    
    // MARK: -- photo
    func captureStillImage() {
        guard let connection: AVCaptureConnection = self.imageOutput.connection(with: .video) else { return }
        
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = self.currentVideoOrientation()
        }
        
        
        
        let completionHandler = { (sampleBuffer: CMSampleBuffer?, error: Error?) in
            guard (sampleBuffer != nil) else { return }
            
            let imageData: Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)!
//            let data: Data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer!,
//                                                                              previewPhotoSampleBuffer: nil)!
            let image: UIImage = UIImage(data: imageData)!
            self.writeImageToAssetsLibrary(image)
        }
        // Capture still image
        self.imageOutput.captureStillImageAsynchronously(from: connection,
                                                         completionHandler: completionHandler)
    }

    // MARK: -- video
    func startRecording() {
        guard !self.isRecording,
            let connection: AVCaptureConnection = self.movieOutput.connection(with: .video)
            else { return }
        
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = self.currentVideoOrientation()
        }
        
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        
        let device: AVCaptureDevice = self.activeCamera()
        if device.isSmoothAutoFocusSupported {
            try? device.lockForConfiguration()
            device.isSmoothAutoFocusEnabled = false
            device.unlockForConfiguration()
        } else {
            try? self.delegate?.deviceConfigurationFailed()
        }
        //
        self.movieOutput.startRecording(to: self.outputURL!, recordingDelegate: self)
    }

    func stopRecording() {
        if self.isRecording {
            self.movieOutput.stopRecording()
        }
    }

    func recordedDuration() -> CMTime { return self.movieOutput.recordedDuration }
}

// Session configuration
extension CameraService {
    
    func configurationSession() throws -> Bool {
        self.captureSession.sessionPreset = self.sessionParent()
        
        // Set up default camera device
        guard let videoDevice: AVCaptureDevice = self.cameras(for: .video).first,
            let videoInput: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            self.captureSession.canAddInput(videoInput)
            else { return false }

        self.captureSession.addInput(videoInput)
        self.activeVideoInput = videoInput

        // Setup default microphone
        guard let audioDevice: AVCaptureDevice = self.cameras(for: .audio).first,
            let audioInput: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
            self.captureSession.canAddInput(audioInput)
            else { return false }
        
        self.captureSession.addInput(audioInput)

        // Setup the still image output
        self.imageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        guard self.captureSession.canAddOutput(self.imageOutput) else { return false }
        self.captureSession.addOutput(self.imageOutput)

        // Setup movie file output
        guard self.captureSession.canAddOutput(self.movieOutput) else { return false }
        self.captureSession.addOutput(self.movieOutput)
        
        /*
        guard try! self.configurationSessionInputs()  else { return false }
        guard try! self.configurationSessionOutputs() else { return false }
         */
        return true
    }
    
    func startSession() {
        DispatchQueue.global().async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        DispatchQueue.global().async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

// Camera Device Support
extension CameraService {
    
    func canSwitchCamera() -> Bool { return self.cameraCount > 1 }
    
    func switchCamera() -> Bool {
        guard self.canSwitchCamera() else { return false }
        
        let videoDevice: AVCaptureDevice = self.inactiveCamera()
        //let videoInput: AVCaptureDeviceInput = try! AVCaptureDeviceInput(device: videoDevice)
        
        guard let videoInput: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            try? self.delegate?.deviceConfigurationFailed()
            return false
        }
        
        self.captureSession.beginConfiguration()
        self.captureSession.removeInput(self.activeVideoInput!)
        
        if self.captureSession.canAddInput(videoInput) {
            self.captureSession.addInput(videoInput)
            self.activeVideoInput = videoInput
        } else {
            self.captureSession.addInput(self.activeVideoInput!)
        }
        self.captureSession.commitConfiguration()
        
        return true
    }
    
    func focusAt(point: CGPoint) {
        let device: AVCaptureDevice = self.activeCamera()
        
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
            try? device.lockForConfiguration()
            device.focusPointOfInterest = point
            device.focusMode = .autoFocus
            device.unlockForConfiguration()
        } else {
            try? self.delegate?.deviceConfigurationFailed()
        }
    }
    
    func exposeAt(point: CGPoint) {
        let device: AVCaptureDevice = self.activeCamera()
        let exposureMode: AVCaptureDevice.ExposureMode = .autoExpose
        
        if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
            try? device.lockForConfiguration()
            device.exposurePointOfInterest = point
            device.exposureMode = exposureMode
            
            if device.isExposureModeSupported(.locked) {
                device.addObserver(self, forKeyPath: OCameraAdjustingExposureKeyPath, options: .new, context: nil)
            }
            device.unlockForConfiguration()
        } else {
            try? self.delegate?.deviceConfigurationFailed()
        }
    }
    
    func resetModes() {
        let device: AVCaptureDevice = self.activeCamera()
        let exposureMode: AVCaptureDevice.ExposureMode = .autoExpose
        let focusMode: AVCaptureDevice.FocusMode = .autoFocus
        let canResetExposure: Bool = device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode)
        let canResetFocus   : Bool = device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode)
        let centerPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
        
        try? device.lockForConfiguration()
        if canResetExposure {
            device.exposureMode = exposureMode
            device.exposurePointOfInterest = centerPoint
        }
        if canResetFocus {
            device.focusMode = focusMode
            device.focusPointOfInterest = centerPoint
        }
        device.unlockForConfiguration()
        
        //try? self.delegate?.deviceConfigurationFailed()
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        
        if (error != nil) {
            try? self.delegate?.mediaCaptureFailed()
        } else {
            self.writeVideoToAssetsLibraryAt(url: self.outputURL!)
        }
        
        self.outputURL = nil
    }
}

extension CameraService {
    
    func postThumbnailNotifyWith(image: UIImage) {
        DispatchQueue.main.async {
            NotificationCenter.post(notification: .GeneraterThumbnail, object: image)
        }
    }
    
    private func writeImageToAssetsLibrary(_ image: UIImage) {
        /*
        let orientation: ALAssetOrientation = ALAssetOrientation(rawValue: Int(Float(image.imageOrientation.rawValue)))!

        ALAssetsLibrary().writeImage(toSavedPhotosAlbum: image.cgImage, orientation: orientation) { (assetURL, error) in
            if error == nil {
                self.postThumbnailNotifyWith(image: image)
            } else {
                try? self.delegate?.assetLibraryWriteFailed()
            }
        }
         */
        
        PHPhotoLibrary.shared().performChanges({
            let _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { (isSuccess, error) in
            if (isSuccess && error == nil) {
                self.postThumbnailNotifyWith(image: image)
            } else {
                try? self.delegate?.assetLibraryWriteFailed()
            }
        })
    }

    private func writeVideoToAssetsLibraryAt(url: URL) {
        /*
        let library: ALAssetsLibrary = ALAssetsLibrary()
        
        let completionBlock = { (assetsURL: URL?, error: Error?) in
            if (error != nil) {
                try self.delegate?.assetLibraryWriteFailed()
            } else {
                self.generatorThumbnailForVideoAt(url: url)
            }
        } as! ALAssetsLibraryWriteVideoCompletionBlock

        if library.videoAtPathIs(compatibleWithSavedPhotosAlbum: url) {
            library.writeVideoAtPath(toSavedPhotosAlbum: url, completionBlock: completionBlock)
        }
         */
        
        if AVAsset(url: url).isCompatibleWithSavedPhotosAlbum {
            PHPhotoLibrary.shared().performChanges({
                let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: { (isSuccess, error) in
                if isSuccess {
                    self.generatorThumbnailForVideoAt(url: url)
                } else {
                    try? self.delegate?.assetLibraryWriteFailed()
                }
            })
        }
    }
    
    private func generatorThumbnailForVideoAt(url: URL) {
        DispatchQueue.global().async {
            let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: AVAsset(url: url))
            generator.maximumSize = CGSize(width: 100.0, height: 0.0)
            generator.appliesPreferredTrackTransform = true
            
            let imageRef = try! generator.copyCGImage(at: CMTime.zero, actualTime: nil)
            let image = UIImage(cgImage: imageRef)
            
            DispatchQueue.main.async {
                self.postThumbnailNotifyWith(image: image)
            }
        }
    }
    
    func activeCamera() -> AVCaptureDevice {
        return self.activeVideoInput?.device ?? AVCaptureDevice.default(for: .video)!
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
        case .portrait:           orientation = .portrait
        case .portraitUpsideDown: orientation = .portraitUpsideDown
        case .landscapeRight:     orientation = .landscapeLeft
        default:                  orientation = .landscapeRight
        }
        return orientation
    }
    
    private func inactiveCamera() -> AVCaptureDevice {
        func cameraWithPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice {
            //let devices: Array = AVCaptureDevice.devices(for: .video)
            let devices: Array = self.cameras(for: .video, position: position)
            
            for device in devices {
                if device.position == position {
                    return device
                }
            }
            return devices.first!
        }
        
        var device: AVCaptureDevice?
        if self.cameraCount > 1 {
            if self.activeCamera().position == .back {
                device = cameraWithPosition(.front)
            } else {
                device = cameraWithPosition(.back)
            }
        }
        return device!
    }
    
    private func cameras(for mediaType: AVMediaType?,
                         position: AVCaptureDevice.Position? = .unspecified) -> [AVCaptureDevice] {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInMicrophone,
            .builtInWideAngleCamera,
            .builtInTelephotoCamera,
            .builtInDualCamera,
            .builtInTrueDepthCamera
        ]
        return AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                mediaType: mediaType,
                                                position: position!).devices
    }
}
