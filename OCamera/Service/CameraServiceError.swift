//
//  CameraServiceError.swift
//  OCamera
//
//  Created by kegebai on 2018/9/27.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation

enum CameraServiceErrorCode: Int {
    case code1 = 1001 // default 1001
    case code2
    case code3
}

enum CameraServiceErrorReason: String {
    case deviceConfigurationFailed // 1001
    case mediaCaptureFailed        // 1002
    case assetLibraryWriteFailed   // 1003
}

struct CameraServiceError: Error {
    var code   : Int    = 0
    var reason : String = ""
    var content: String?
    
    private(set) var desc: String {
        set {}
        get { return self.desc() }
    }
    
    init(code: CameraServiceErrorCode, reason: CameraServiceErrorReason, content: String? = "") {
        self.code    = code.rawValue
        self.reason  = reason.rawValue
        self.content = content
    }
}
