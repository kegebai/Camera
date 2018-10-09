//
//  VideoRecordService.swift
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

protocol TargetImage {
    func setImage(from ciimage: CIImage)
}

class VideoRecordService: CameraService {
    var target: TargetImage?
    
//    private var outputURL: URL {
//        get {
//            let dirPath: String = FileManager.temporaryDirectoryWithTemplateString("OCamera.xxx")
//            guard dirPath != "" else { return URL(fileURLWithPath: "") }
//            
//            let filePath: String = dirPath.appending("ocamera_movie.mov")
//            return URL(fileURLWithPath: filePath)
//        }
//    }
    
    private var videoDataOutput: AVCaptureVideoDataOutput
    private var audioDataOutput: AVCaptureVideoDataOutput
    
    private var videoWriter: WriterService
    
    override init() {
        self.videoDataOutput = AVCaptureVideoDataOutput()
        self.videoDataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = false
        self.audioDataOutput = AVCaptureVideoDataOutput()
        let videoSettings    = self.videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov)
        let audioSettings    = self.audioDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov)
        self.videoWriter     = WriterService(videoSettings: videoSettings!, audioSettings: audioSettings!)
        
        super.init()
        
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        self.audioDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        self.videoWriter.delegate = self
    }
    
    override func configurationSessionOutputs() throws -> Bool {
        // Setup the still image output
        self.imageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        guard self.captureSession.canAddOutput(self.imageOutput) else { return false }
        
        self.captureSession.addOutput(self.imageOutput)
        
        // Setup movie file output
        guard self.captureSession.canAddOutput(self.movieOutput) else { return false }
        
        self.captureSession.addOutput(self.movieOutput)

        return true
    }
    
    override func startRecording() {
        guard !self.isRecording,
            let connection: AVCaptureConnection = self.movieOutput.connection(with: .video) else { return }

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

        self.movieOutput.startRecording(to: self.outputURL, recordingDelegate: self)
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

extension VideoRecordService: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

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

extension VideoRecordService: WriterServiceDelegate {

    func writerServiceDidWriteVideoAtURL(_ videoURL: URL) {
        self.writeVideoToAssetsLibraryAt(url: videoURL)
    }
}

extension VideoRecordService {
    
    private func writeVideoToAssetsLibraryAt(url: URL) {
//        let library: ALAssetsLibrary = ALAssetsLibrary()
//        let completionBlock: ALAssetsLibraryWriteVideoCompletionBlock = { (assetsURL: URL?, error: Error?) in
//            if (error == nil) {
//                self.thumbnailForVideoAt(url: url)
//            } else {
//                try self?.delegate?.assetLibraryWriteFailed()
//            }
//        }
//
//        if library.videoAtPathIs(compatibleWithSavedPhotosAlbum: url) {
//            library.writeVideoAtPath(toSavedPhotosAlbum: url, completionBlock: completionBlock)
//        }
        
        if AVAsset(url: url).isCompatibleWithSavedPhotosAlbum {
            PHPhotoLibrary.shared().performChanges({
                let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: { (isSuccess, error) in
                if isSuccess && (error == nil) {
                    self.thumbnailForVideoAt(url: url)
                } else {
                    try? self.delegate?.assetLibraryWriteFailed()
                }
            })
        }
    }
    
    private func thumbnailForVideoAt(url: URL) {
        DispatchQueue.global().async {
            let asset: AVAsset = AVAsset(url: url)
            let imageGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.maximumSize = CGSize(width: 100.0, height: 0.0)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let imageRef = try! imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
            let image = UIImage(cgImage: imageRef)
            
            DispatchQueue.main.async {
                self.postThumbnailNotifyWith(image: image)
            }
        }
    }
}

