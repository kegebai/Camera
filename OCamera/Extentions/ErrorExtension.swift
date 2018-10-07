//
//  ErrorExtension.swift
//  OCamera
//
//  Created by kegebai on 2018/9/27.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation

extension Error {
    
    public func desc(file: String = #file, function: String = #function, line: Int = #line) -> String {
        return "Method: \(function) FileName: \(file) LineNo: \(line)"
    }
}
