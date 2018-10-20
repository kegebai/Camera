//
//  FileManagerExtention.swift
//  OCamera
//
//  Created by kegebai on 2018/9/23.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation

extension FileManager {
    
    static func temporaryDirectoryWithTemplateString(_ templateString: String) -> String? {
        var directoryPath: String = ""
        
        let mkdTemplate: String = NSTemporaryDirectory().appending(templateString)
        
        let templateCString = mkdTemplate.cString(using: .utf8)
        
        let buffer = malloc(strlen(templateCString) + 1)?.assumingMemoryBound(to: Int8.self)
        
        strcpy(buffer, templateCString)
        
        let result = mkdtemp(buffer)
        
        if (result != nil) {
            directoryPath = FileManager.default.string(withFileSystemRepresentation: buffer!, length: strlen(result))
        }
        free(buffer)
        
        return directoryPath
    }
}
