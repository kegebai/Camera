//
//  WriterService.swift
//  OCamera
//
//  Created by kegebai on 2018/9/24.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage
import UIKit

@objc protocol WriterServiceDelegate {
    func writerServiceDidWriteVideoAtURL(_ videoURL: URL)
}

class WriterService {
    weak var delegate: WriterServiceDelegate?
    
    private(set) var isWriting: Bool = false
    
    private var assetWriter: AVAssetWriter!
    private var assetVideoInput: AVAssetWriterInput!
    private var assetAudioInput: AVAssetWriterInput!
    private var assetInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    private var ciContext   : CIContext
    private var colorSpace  : CGColorSpace
    private var activeFilter: CIFilter
    
    private var videoSettings: [String: Any]
    private var audioSettings: [String: Any]
    
    private var firstSample: Bool = true
    
    init(videoSettings: [String: Any], audioSettings: [String: Any]) {
        self.videoSettings = videoSettings
        self.audioSettings = audioSettings
        //
        self.ciContext     = ContextManager.default.ciContext
        self.colorSpace    = CGColorSpaceCreateDeviceRGB()
        self.activeFilter  = PhotoFilter.defaultFilter()
        
        NotificationCenter.observe(self, notification: .FilterSelectionChanged, selector: #selector(filterChanged(_:)))
    }
}

extension WriterService {
    
    func start() {
        DispatchQueue.global().async {
            var error: Error?
            self.assetWriter = try! AVAssetWriter(outputURL: outputURL(), fileType: .mov)
            
            guard self.assetWriter != nil else { return }
            
            self.assetVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.videoSettings)
            self.assetVideoInput.expectsMediaDataInRealTime = true
            let orientation: UIDeviceOrientation = UIDevice.current.orientation
            self.assetVideoInput.transform = TransformDevice(orientation: orientation)
            
            let attributes: [String: Any] = [
                String(kCVPixelBufferPixelFormatTypeKey)   : kCVPixelFormatType_32BGRA,
                String(kCVPixelBufferWidthKey)             : self.videoSettings[AVVideoWidthKey]!,
                String(kCVPixelBufferHeightKey)            : self.videoSettings[AVVideoHeightKey]!,
                String(kCVPixelFormatOpenGLESCompatibility): kCFBooleanTrue
            ]
            self.assetInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.assetVideoInput,
                                                                                     sourcePixelBufferAttributes: attributes)
            
            guard self.assetWriter.canAdd(self.assetVideoInput) else {
                print("Unable to add video input.")
                return
            }
            self.assetWriter.add(self.assetVideoInput)
            
            self.assetAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: self.audioSettings)
            self.assetAudioInput.expectsMediaDataInRealTime = true
            guard self.assetWriter.canAdd(self.assetAudioInput) else {
                print("Unable to add audio input.")
                return
            }
            self.assetWriter.add(self.assetAudioInput)
            
            self.isWriting = true
            self.firstSample = true
        }
        
        func outputURL() -> URL {
            let path: String = NSTemporaryDirectory().appending("movie.mov")
            let url: URL = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                try! FileManager.default.removeItem(at: url)
            }
            return url
        }
    }
    
    func stop() {
        self.isWriting = false
        DispatchQueue.global().async {
            self.assetWriter.finishWriting(completionHandler: {
                if self.assetWriter.status == .completed {
                    DispatchQueue.main.async {
                        self.delegate?.writerServiceDidWriteVideoAtURL(self.assetWriter.outputURL)
                    }
                } else {
                    print("Failed to write movie: " + (self.assetWriter.error?.localizedDescription)!)
                }
            })
        }
    }
    
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard self.isWriting else { return }
        
        let fmtDesc: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        let mediaType: CMMediaType = CMFormatDescriptionGetMediaType(fmtDesc)
        
        if mediaType == kCMMediaType_Video {
            let timeStemp: CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if self.firstSample {
                if self.assetWriter.startWriting() {
                    self.assetWriter.startSession(atSourceTime: timeStemp)
                } else {
                    print("Failed to start writing.")
                }
                self.firstSample = false
            }
            
            let pixelBufferOut_ptr: UnsafeMutablePointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 0)
            //let pixelBufferOut: CVPixelBuffer
            let pixelBufferPool: CVPixelBufferPool = self.assetInputPixelBufferAdaptor.pixelBufferPool!
            
            let error: OSStatus? = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, pixelBufferOut_ptr.predecessor())
            
            guard error == nil else {
                print("Unable to obtain a pixel buffer from the pool.")
                return
            }
            
            let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let sourceImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
            self.activeFilter.setValue(sourceImage, forKey: kCIInputImageKey)
            var filterImage: CIImage? = self.activeFilter.outputImage
            
            if (filterImage == nil) {
                filterImage = sourceImage
            }
            
            self.ciContext.render(filterImage!,
                                  to: pixelBufferOut_ptr as! CVPixelBuffer,
                                  bounds: filterImage!.extent,
                                  colorSpace: self.colorSpace)
            
            if self.assetVideoInput.isReadyForMoreMediaData {
                if !self.assetInputPixelBufferAdaptor.append(pixelBufferOut_ptr as! CVPixelBuffer, withPresentationTime: timeStemp) {
                    print("Error appending pixel buffer.")
                }
            }
        }
        else if !self.firstSample && mediaType == kCMMediaType_Audio {
            if self.assetAudioInput.isReadyForMoreMediaData {
                if !self.assetAudioInput.append(sampleBuffer) {
                    print("Error appending audio sample buffer.")
                }
            }
        }
    }
}

extension WriterService {
    
    @objc private func filterChanged(_ noti: Notification) {
        self.activeFilter = noti.object as! CIFilter
    }
}
