//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by 张凯 on 2020/6/28.
//  Copyright © 2020 zhiyi. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    // 响应变化
    @ObservedObject var document:EmojiArtDocument
    @State private var paletteChooseing = ""
    
    var body: some View {
        VStack{
            HStack{
                PaletteChooser(document: self.document,paletteChooseing: $paletteChooseing)
                ScrollView(.horizontal){
                    // 可遍历的必须是一组实现identi的数组
                    HStack{
                        ForEach(paletteChooseing.map{ return String($0)},id:\.self){ emoji in
                            Text(emoji)
                                .onDrag{ return NSItemProvider(object: emoji as NSString)}
                                .font(Font.system(size: self.emojiSize))
                        }
                    }
                    .onAppear{self.paletteChooseing = self.document.defaultPalette}
                }
            }
            GeometryReader { geometry in
                ZStack{
                    Color.orange.overlay(
                        // 因为self.document.backgroundImage是一个可选的，所以通过自建的view，一定会返回一个view
                        OptionImage(image: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffSet)
                            //$backgroundImages是一个publisher
                            .onReceive(self.document.$backgroundImage){ backgroundImage in
                                self.zoomToFit(backgroundImage, in: geometry.size)
                            }
                        )
                        .gesture(self.onDoubleTapToZoom(in:geometry.size))
                        .gesture(self.panGesture())
                    if self.isLoading{
                        // 正在载入图片
                        // spinning是一个函数
                        Image(systemName: "trash").imageScale(.large).spinning()
                    }else {
                        ForEach(self.document.emojis) {emoji in
                            Text(emoji.text)
                                // 这边是因为默认的emoji变化的动画不好，自己修改了
                                .font(animatableWithSize: emoji.fontSize * self.zoomScale)
                                .position(self.position(for:emoji,at: geometry.size))
                        }
                    }
                }
                    .clipped() // 不会盖住顶上的滚动表情
                    .gesture(self.pinch())
                    .edgesIgnoringSafeArea([.horizontal,.bottom])
                    .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers,location in
                       // 在dropemoji的时候需要用到 location
                       var location = geometry.convert(location, from: .global)
                       location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                        location =  CGPoint(x: location.x - self.panOffSet.width, y: location.y - self.panOffSet.height)
                        location = CGPoint(x:location.x/self.zoomScale,y:location.y/self.zoomScale)
                       return self.drop(providers:providers,at:location)
                    }
            }
        }
    }
    //
    var isLoading:Bool{
        document.backGroundURL != nil && document.backgroundImage == nil
    }
    
    
    // 增加pan手势
    
    // 开始和结束的值
    @State private var steadyStatePanOffset:CGSize = .zero
    // 在手势结束后会变成初始值
    @GestureState private var gesturePanOffset:CGSize = .zero
    
    // 在过程中的值是两者的结合
    private var panOffSet:CGSize{
        //print(self.gesturePanOffset)
        return (self.steadyStatePanOffset + self.gesturePanOffset) * zoomScale
    }
    // 平移移动
    private func panGesture() -> some Gesture{
        DragGesture().updating($gesturePanOffset){value,gesturePanOffset,transitions in
            gesturePanOffset = value.translation / self.zoomScale
        }.onEnded { value in
            self.steadyStatePanOffset =  self.steadyStatePanOffset + value.translation / self.zoomScale
        }
    }
    
    // 在连续的手势下，需要这个状态，然后在手势结束后会变回原来的
    @GestureState private var gestureZoomScale:CGFloat = 1.0
    
    @State private var steadyStateZoomScale:CGFloat = 1.0
    
    private var zoomScale: CGFloat{
        // 只读的
        //print("gestureZoomScale:\(gestureZoomScale)")
        return self.gestureZoomScale * self.steadyStateZoomScale
    }
    
    //
    private func pinch() -> some Gesture{
        // 连续的动画
        MagnificationGesture()
            .updating($gestureZoomScale) { value, gestureZoomScale, transition in
                gestureZoomScale = value
            }
            .onEnded { value in
                self.steadyStateZoomScale *= value
        }
    }
    
    
    
    // 双击时，会改变steadyStateZoomScale，
    private func onDoubleTapToZoom(in size:CGSize) -> some Gesture{
        TapGesture(count: 2).onEnded{
            // animation要具体到一个
            withAnimation(.linear(duration: 0.75)){
                self.zoomToFit(self.document.backgroundImage,in:size)
            }
                   
        }
    }
    // 图片最适合的大小
    private func zoomToFit(_ image:UIImage?,in size:CGSize){
        if let image = image,image.size.width>0,image.size.height>0{
            let hScale = size.width / image.size.width
            let zScale = size.height / image.size.height
            self.steadyStateZoomScale = min(hScale,zScale)
        }
    }
    
//    private func font(for emoji:EmojiArtModel.Emoji) -> Font{
//        // 这边的emoji.size是int类型的，从model应该在vm中
//        return Font.system(size: emoji.fontSize * zoomScale)
//    }
    private func position(for emoji:EmojiArtModel.Emoji,at size:CGSize) -> CGPoint{
        var location = emoji.location
        location = CGPoint(x:location.x + self.panOffSet.width,y:location.y + self.panOffSet.height)
        location = CGPoint(x:location.x * self.zoomScale,y:location.y * self.zoomScale)
        return CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
    }
    
    private func drop(providers:[NSItemProvider],at location:CGPoint) -> Bool {
        // 把网址drop里面是很快的，
        var found = providers.loadObjects(ofType: URL.self){ url in
            //print("dropped \(url)")
            self.document.backGroundURL = url
        }
        // 如果不是图片就是emoji
        if !found{
            found = providers.loadObjects(ofType: String.self) { string in
                // view直接利用vm
                self.document.addEmoji(emoji: string, location: location, size: self.emojiSize)
            }
        }
        return found
    }

    
    
    // MARK: contant
    private let emojiSize:CGFloat = 40
}


struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
