//
//  PhotoService.swift
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

class PhotoService: CameraService {
    
    override init() {
        super.init()
    }
    
    override func captureStillImage() {
        guard let connection: AVCaptureConnection = self.imageOutput.connection(with: .video) else { return }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = self.currentVideoOrientation()
        }

        let completionHandler = { (sampleBuffer: CMSampleBuffer?, error: Error?) in
            guard (sampleBuffer != nil) else { return }
            
            let imageData: Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)!
            let image: UIImage = UIImage(data: imageData)!
            self.writeImageToAssetsLibrary(image)
        }

        // Capture still image
        self.imageOutput.captureStillImageAsynchronously(from: connection,
                                                         completionHandler: completionHandler)
    }
}

// Still Image Capture
extension PhotoService {
    
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
                print(error as Any)
            }
        })
    }
}

