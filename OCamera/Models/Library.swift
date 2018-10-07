//
//  Library.swift
//  OCamera
//
//  Created by kegebai on 2018/9/24.
//  Copyright © 2018年 kegebai. All rights reserved.
//

import Foundation
import AssetsLibrary
import UIKit

class Library {
    typealias CompletionHandle = ((_ success: Bool, _ error: Error) -> ())?
    private var assetsLibrary: ALAssetsLibrary = ALAssetsLibrary()
    
    func writeImage(_ image: UIImage, completion: CompletionHandle) {
        
    }
    
    func writeVideo(AtURL videoURL: URL, completion: CompletionHandle) {
        
    }
}
