//
//  FaceDetectionService.swift
//  OCamera
//
//  Created by kegebai on 2018/9/23.
//  Copyright © 2018 kegebai. All rights reserved.
//

import Foundation
import AVFoundation

class FaceDectectionService: CameraService {
    
    override init() {
        super.init()
    }
    
    override func configurationSessionOutputs() throws -> Bool {

        guard self.captureSession.canAddOutput(self.metadataOutput) else {
            throw CameraServiceError.deviceConfigurationFailed
        }
        
        self.captureSession.addOutput(self.metadataOutput)
        
        let metadataObjectTypes: Array = [AVMetadataObject.ObjectType.face]
        self.metadataOutput.metadataObjectTypes = metadataObjectTypes
        
        self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        return true
    }
}

//extension FaceDectectionService: AVCaptureMetadataOutputObjectsDelegate {
//    func metadataOutput(_ output: AVCaptureMetadataOutput,
//                        didOutput metadataObjects: [AVMetadataObject],
//                        from connection: AVCaptureConnection) {
//        for obj: AVMetadataObject in metadataObjects {
//            print(obj.type)
//        }
//        self.detectionFaceDelegate?.detection(faces: metadataObjects)
//    }
//}
