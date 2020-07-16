//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by 张凯 on 2020/7/6.
//  Copyright © 2020 zhiyi. All rights reserved.
//

import SwiftUI

struct PaletteChooser: View {
    // 需要从外面传值的初始化的属性都不能private
    @ObservedObject var document:EmojiArtDocument
    @Binding var paletteChooseing:String
    
    @State private var show:Bool = false
    
    var body: some View {
        HStack{
            // 一个正负号
            Stepper(onIncrement: {
                self.paletteChooseing = self.document.palette(after: self.paletteChooseing)
            }, onDecrement: {
                self.paletteChooseing = self.document.palette(before:self.paletteChooseing)
            }, label: {
                EmptyView()
            })
            Text(self.document.paletteNames[self.paletteChooseing] ?? "")
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture {
                    // 为什么这里没有改变回去就默认回去了呢，@gestrueState是自动回去的，这里为什么会自动回去了呢
                    self.show = true
                }
                .popover(isPresented: $show){
                    PaletteEditor(paletteChooseing: self.$paletteChooseing)
                        .environmentObject(self.document)
                        .frame(minWidth:300, minHeight:300)
                }
        }
        .fixedSize(horizontal: true, vertical: false) // 只会占用适合自己的空间
    }
}

// 弹出框
struct PaletteEditor:View {
    //Bingding不是也可以，是不行。。。vm的共享，用environmentObject
    @EnvironmentObject var document:EmojiArtDocument
    //选择的那些表情
    @Binding var paletteChooseing:String
    // 输入框中的名字
    @State private var paletteEditing:String = ""
    //输入的表情
    @State private var emojiToAdd:String = ""
    
    var body:some View{
        VStack{
            Text("Palette Editor").font(.headline).padding()
            Form{
                Section{
                    TextField("Emoji Catalog", text: self.$paletteEditing,onEditingChanged: {begin in
                        // 如果不加！begin，会调用两次
                        if !begin{
                            //print("1")
                            self.document.renamePalette(self.paletteChooseing, to: self.paletteEditing)
                        }
                    })
                    TextField("Emoji Add", text: self.$emojiToAdd,onEditingChanged: {begin in
                        // 如果不加！begin，会调用两次
                        if !begin{
                            //print("1")
                            self.paletteChooseing = self.document.addEmoji(self.emojiToAdd, toPalette: self.paletteChooseing)
                        }
                    })
                }
//                Section(header:Text("Remove Emoji")){
//                    VStack{
//                        // swift 中的\是什么意思呢
//                        ForEach(self.paletteChooseing.map{String($0)}){ emoji in
//                            Text(emoji)
//                                .onTapGesture {
//                                    self.paletteChooseing = self.document.removeEmoji(emoji, fromPalette: self.paletteChooseing)
//                                }
//                        }
//                    }
//                }
            }
        }
            .onAppear{self.paletteEditing = self.document.paletteNames[self.paletteChooseing] ?? ""}
    }
}



struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(),paletteChooseing: Binding.constant(""))
    }
}
