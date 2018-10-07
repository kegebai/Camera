//
//  Functions.swift
//  OCamera
//
//  Created by kegebai on 2018/9/24.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import UIKit

@inline(__always) func TransformDevice(orientation: UIDeviceOrientation) -> CGAffineTransform {
    var result: CGAffineTransform
    
    switch orientation {
    case .landscapeRight:     result = CGAffineTransform(rotationAngle: .pi)
    case .portraitUpsideDown: result = CGAffineTransform(rotationAngle: .pi * 3)
    
    case .portrait, .faceUp, .faceDown:
        result = CGAffineTransform(rotationAngle: .pi / 2)
        
    default: // Default orientation of landscape left
        result = CGAffineTransform.identity
    }
    return result
}
