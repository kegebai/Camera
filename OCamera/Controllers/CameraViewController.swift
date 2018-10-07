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

class CameraViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let cameraView = CameraView(frame: self.view.bounds)
        cameraView.overlayView.modeBar.thumbnailButton.addTarget(self,
                                                                 action: #selector(openCameraRoll(_:)),
                                                                 for: .touchUpInside)
        self.view.addSubview(cameraView)
        
        //
        let viewModel = CameraViewModel()
        
        if (try! viewModel.cameraService.configurationSession()) {
            cameraView.bind(viewModel: viewModel)
            viewModel.cameraService.startSession()
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
