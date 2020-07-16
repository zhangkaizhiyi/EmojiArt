//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by 张凯 on 2020/6/29.
//  Copyright © 2020 zhiyi. All rights reserved.
//

import Foundation

struct  EmojiArtModel:Codable {
    var backgroundURL:URL?
    
    // 这已经创建了一个空数组了，如果是类型的话，需要这样写Array<Emoji>,然后在init中初始化
    var emojis = [Emoji]()
    
    var json:Data?{
        //  转化为json
        return try? JSONEncoder().encode(self)
    }
    
    init?(json:Data?) {
        if json != nil,let emojiArt = try? JSONDecoder().decode(EmojiArtModel.self, from: json!) {
            self = emojiArt
        }else {
            return nil
        }
    }
    // 默认的init方法
    init() {}
    
    private var uniqueEmojiId = 0
    // 所有的emoji都必须经过这个函数生成，产生唯一的id，且在外面是可以改的，所以不能用private（set） emojis
    mutating func addEmoji(x:Int,text:String,y:Int,size:Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(x: x, text: text, y: y, size: size, id: uniqueEmojiId))
    }
    
    struct Emoji:Identifiable,Codable {
        // 这里的let与var
        let text:String
        var x:Int
        var y:Int
        var size:Int
        let id: Int
        // 之所以要加这个保护是因为不想emoji在外面创建，但外面可以修改，每一个emoji的创建都要经过addEMoji函数，产生唯一的id
        fileprivate init(x:Int,text:String,y:Int,size:Int,id: Int){
            self.x = x
            self.y = y
            self.size = size
            self.text = text
            self.id = id
        }
    }
}

