//
//  ContextManager.swift
//  OCamera
//
//  Created by kegebai on 2018/9/24.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

class ContextManager {
    static let `default`: ContextManager = ContextManager()
    private init() {}
    
    private(set) var ciContext: CIContext {
        set {}
        get {
            return CIContext(eaglContext: EAGLContext(api: .openGLES2)!,
                             options: [.workingColorSpace: (Any).self])
        }
    }
}
