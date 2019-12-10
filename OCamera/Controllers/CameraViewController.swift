//
//  CameraViewController.swift
//  OCamera
//
//  Created by kegebai on 2018/9/26.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit
import CoreServices
import AVFoundation

class CameraViewController: UIViewController {
    
    lazy var cameraView: CameraView = {
        let view: CameraView = CameraView(frame: self.view.bounds)
        view.overlayView.modeBar.thumbnailButton.addTarget(self, action: #selector(openCameraRoll(_:)), for: .touchUpInside)
        return view
    }()
    
    private(set) var cameraService: CameraService = CameraService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.addSubview(self.cameraView)
        
        //
        if (try! self.cameraService.configurationSession()) {
            self.cameraView.bind(service: self.cameraService)
            self.cameraService.startSession()
        }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
}

extension CameraViewController {
    @objc private func openCameraRoll(_ sender: UIButton) {
        let pickerController: UIImagePickerController = UIImagePickerController()
        pickerController.sourceType = .photoLibrary
        pickerController.mediaTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        self.present(pickerController, animated: true, completion: nil)
    }
}
