//
//  ViewModel.swift
//  OCamera
//
//  Created by kegebai on 2018/9/25.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CameraViewModel {
    var cameraMode: CameraMode = .video
    
    private(set) var cameraService: CameraService = CameraService()
    
    private var timer: Timer!
    private var thumbnail: UIImage?
    
    init() {
        NotificationCenter.observe(self,
                                   notification: .GeneraterThumbnail,
                                   selector: #selector(generateThumbnail(_:)))
        self.cameraService.delegate = self
    }
}

extension CameraViewModel: CameraServiceDelegate {
    
    func deviceConfigurationFailed() throws {
        
    }
    
    func mediaCaptureFailed() throws {
        
    }
    
    func assetLibraryWriteFailed() throws {
        
    }
}

extension CameraViewModel {
    func startTimer() {
        //self.timer.invalidate()
        self.timer = Timer(timeInterval: 0.5,
                           target: self,
                           selector: #selector(updateTimeDisplay),
                           userInfo: nil,
                           repeats: true)
        RunLoop.current.add(self.timer, forMode: .common)
    }
    
    func stopTimer() {
        self.timer.invalidate()
    }
}

extension CameraViewModel {
    
    @objc func updateTimeDisplay() -> String {
        let duration: CMTime = self.cameraService.recordedDuration()
        let time   : Int = Int(CMTimeGetSeconds(duration))
        let hours  : Int = time / 3600
        let minutes: Int = time / 60 % 60
        let seconds: Int = time % 60
        
        let fmt: String = "%02i:%02i:%02i"
        let tempString: String = String(format: fmt, hours, minutes, seconds)
        
        return tempString
    }

    func updateThumbnail() -> UIImage? { return self.thumbnail }
}

extension CameraViewModel {
    
    @objc private func generateThumbnail(_ noti: Notification) {
        self.thumbnail = noti.object as? UIImage
    }
}
