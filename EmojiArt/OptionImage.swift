//
//  OptionImage.swift
//  EmojiArt
//
//  Created by 张凯 on 2020/6/30.
//  Copyright © 2020 zhiyi. All rights reserved.
//

import SwiftUI

struct OptionImage: View {
    var image:UIImage?
    
    // 如果没有image，仍然是一个view
    var body: some View {
        Group {
            if image != nil {
                Image(uiImage: image!)
            }
        }
    }
}

