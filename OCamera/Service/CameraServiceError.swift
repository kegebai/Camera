//
//  CameraServiceError.swift
//  OCamera
//
//  Created by kegebai on 2018/9/27.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation

struct CameraServiceError: Error {
    var code   : Int    = 0
    var reason : String = ""
    var content: String?
    
    private(set) var desc: String {
        set {}
        get { return self.desc() }
    }
    
    init(code: Int, reason: String, content: String? = "") {
        self.code    = code
        self.reason  = reason
        self.content = content
    }
}
