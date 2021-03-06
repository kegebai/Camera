//
//  VideoService.swift
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

@objc protocol TargetImage { func setImage(from ciimage: CIImage) }

class VideoService: CameraService {
    weak var target: TargetImage?
    
    private var videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    private var audioDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    private var videoWriter: WriterService
    
    override init() {
        let videoSettings = self.videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov)
        let audioSettings = self.audioDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov)
        self.videoWriter  = WriterService(videoSettings: videoSettings!, audioSettings: audioSettings!)
        
        super.init()
        
        self.videoDataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = false
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        self.audioDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        self.videoWriter.delegate = self
    }
    
    override func configurationSessionOutputs() throws -> Bool {
        // Setup movie file output
        guard self.captureSession.canAddOutput(self.movieOutput) else {
            throw CameraServiceError.deviceConfigurationFailed
        }
        
        self.captureSession.addOutput(self.movieOutput)

        return true
    }
    
    override func startRecording() throws {
        guard !self.isRecording else { return }
        
        let connection: AVCaptureConnection = self.movieOutput.connection(with: .video)!

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = self.currentVideoOrientation()
        }

        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }

        let device: AVCaptureDevice = self.activeCamera()
        if device.isSmoothAutoFocusSupported {
            do {
                try device.lockForConfiguration()
                device.isSmoothAutoFocusEnabled = false
                device.unlockForConfiguration()
            } catch let error {
                print(error)
            }
        } else {
            throw CameraServiceError.deviceConfigurationFailed
        }

        self.movieOutput.startRecording(to: self.outputURL!, recordingDelegate: self)
    }
    
    override func stopRecording() {
        if self.isRecording {
            self.movieOutput.stopRecording()
        }
    }
    
    override func recordedDuration() -> CMTime {
        return self.movieOutput.recordedDuration
    }
}

extension VideoService: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        self.videoWriter.processSampleBuffer(sampleBuffer)

        if output == self.movieOutput {
            let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let sourceImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
            self.target?.setImage(from: sourceImage)
        }
    }
}

extension VideoService: WriterServiceDelegate {

    func writerServiceDidWriteVideoAtURL(_ videoURL: URL) {
        self.writeVideoToAssetsLibraryAt(url: videoURL)
    }
}

extension VideoService {
    
    private func writeVideoToAssetsLibraryAt(url: URL) {
        /*
        let library: ALAssetsLibrary = ALAssetsLibrary()
        let completionBlock = { (assetsURL: URL?, error: Error?) in
            if (error == nil) {
                self.generatorthumbnailForVideoAt(url: url)
            } else {
                try self?.delegate?.assetLibraryWriteFailed()
            }
        }

        if library.videoAtPathIs(compatibleWithSavedPhotosAlbum: url) {
            library.writeVideoAtPath(toSavedPhotosAlbum: url, completionBlock: completionBlock)
        }
         */
 
        if AVAsset(url: url).isCompatibleWithSavedPhotosAlbum {
            PHPhotoLibrary.shared().performChanges({
                let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: { (isSuccess, error) in
                if isSuccess {
                    self.generatorthumbnailForVideoAt(url: url)
                } else {
                    print(error as Any)
                }
            })
        }
    }
    
    private func generatorthumbnailForVideoAt(url: URL) {
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
}

