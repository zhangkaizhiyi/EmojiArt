//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by 张凯 on 2020/6/28.
//  Copyright © 2020 zhiyi. All rights reserved.
// 这是vm

import SwiftUI
// 引入combine是为了publiser的sink
import Combine
// 响应变化
class EmojiArtDocument:ObservableObject{
    // 为什么是static是因为这是一个通用的，而不是单独的实例
    static let platetee = "🐝🐽🐞🐤🦋🦂"
    // 保持响应式变化需要在vm中加这个，当model变化时，发布，然后vm的变化被view监测到
    @Published private var emojiArt:EmojiArtModel
    
    // 得到url后我们把url转化为view,这个也是intends,也是操作model
    @Published private(set) var backgroundImage: UIImage?
    
    var emojis:[EmojiArtModel.Emoji] { emojiArt.emojis}
    
    private static let until = "EmojiArtDocument.Untile"
    
    private var emojiSub:AnyCancellable?
    
    init() {
        emojiArt = EmojiArtModel(json: UserDefaults.standard.data(forKey: EmojiArtDocument.until)) ?? EmojiArtModel()
        // $emojiArt是一个publiser
        emojiSub = $emojiArt.sink{ emoji in
            print("emojiDoucemnt:\(emoji)\t")
            UserDefaults.standard.set(emoji.json, forKey: EmojiArtDocument.until)
        }
        fetchBackGroundImageData()
    }
    // MARK: -intends
    
    
    func addEmoji(emoji:String,location:CGPoint,size:CGFloat){
        // 这里要对cgfloat转化，因为model是独立的，不能有cgfloat之类的，
        emojiArt.addEmoji(x: Int(location.x), text:emoji, y: Int(location.y), size: Int(size))
    }
    // 我们的model是存储了一幅画中的所有图片和emoji，操作里面的emoji放大
    func scaleEmoji(emoji:EmojiArtModel.Emoji,by scale:CGFloat) {
        // 找到那个emoji，才能操作,把那个emoji的属性变化了
        if let index = emojiArt.emojis.firstIndex(matching:emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    func moveEmoji(emoji:EmojiArtModel.Emoji,by offset:CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching:emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    //这些都是操作model的
    var backGroundURL:URL? {
        set{
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackGroundImageData()
        }
        get {
            emojiArt.backgroundURL
        }
        
    }
    private var backgroundImageCancellable:AnyCancellable?
    // 获得图片数据
    private func fetchBackGroundImageData(){
        backgroundImage = nil
        if let url = emojiArt.backgroundURL{
//            DispatchQueue.global().async {
//                // 这个data函数本身耗费时间
//                if let imageData = try?Data(contentsOf: url){
//                    DispatchQueue.main.async {
//                        // 确保回来时，还是那个url
//                        if url == self.emojiArt.backgroundURL{
//                            self.backgroundImage = UIImage(data: imageData)
//                        }
//                    }
//                }
//            }
           // publisher本质是当变化的时候，做任务，只要是会变化的东西，都可以用来publiser，当变化的时候，published
            // 这边dataTask默认放在了global中
            // 当点击新的任务时，默认取消之前的进程
            backgroundImageCancellable?.cancel()
            backgroundImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map{data,response in UIImage(data: data)}
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .assign(to: \EmojiArtDocument.backgroundImage, on: self)
        }
    }
    
}

extension EmojiArtModel.Emoji{
    var fontSize:CGFloat {CGFloat(self.size)}
    var location:CGPoint {CGPoint(x:CGFloat(self.x),y:CGFloat(self.y))}
}
