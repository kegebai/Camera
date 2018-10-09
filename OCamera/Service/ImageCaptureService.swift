//
//  ImageCaptureService.swift
//  OCamera
//
//  Created by kegebai on 2018/9/24.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import AssetsLibrary
import Photos

class ImageCaptureService: CameraService {
    
    override init() {
        super.init()
    }
    
    override func captureStillImage() {
        guard let connection: AVCaptureConnection = self.imageOutput.connection(with: .video) else { return }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = self.currentVideoOrientation()
        }

        let handle = { (sampleBuffer: CMSampleBuffer?, error: Error?) in
            if sampleBuffer != nil {
                let imageData: Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)!
                let image: UIImage = UIImage(data: imageData)!
                self.writeImageToAssetsLibrary(image)
            }
        }

        // Capture still image
        self.imageOutput.captureStillImageAsynchronously(from: connection, completionHandler: handle)
    }
}

// Still Image Capture
extension ImageCaptureService {
    
    private func writeImageToAssetsLibrary(_ image: UIImage) {
//        let library: ALAssetsLibrary = ALAssetsLibrary()
//        let orientation: ALAssetOrientation = ALAssetOrientation(rawValue: Int(Float(image.imageOrientation.rawValue)))!
//
//        library.writeImage(toSavedPhotosAlbum: image.cgImage, orientation: orientation) { (assetURL, error) in
//            if error == nil {
//                self.postThumbnailNotifyWith(image: image)
//            } else {
//                try? self.delegate?.assetLibraryWriteFailed()
//            }
//        }
        
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
}

