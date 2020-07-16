//
//  Spinning.swift
//  EmojiArt
//
//  Created by 张凯 on 2020/7/2.
//  Copyright © 2020 zhiyi. All rights reserved.
//

import SwiftUI

// modifier本质上类似css，吧一种view变成另一种view

struct Spinning:ViewModifier {
    @State private var isVisable = false
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle.degrees(self.isVisable ? 360:0))
            .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false))
            .onAppear{
                    self.isVisable = true
            }
    }
}

extension View{
    // modifier 还是要返回一些view
    func spinning() -> some View{
        self.modifier(Spinning())
    }
    
}
