//
//  Button.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/22.
//

import SwiftUI

struct ButtonTest: View {
    @State private var isExpanded = false
    @Namespace private var namespace
    var body: some View {
        
        ZStack{
            Image("myImageName").resizable()
            
            ScrollView(.vertical, showsIndicators: false){
                VStack{
                    
                    // 最基本用法（預設 Capsule 形狀 + .regular 變體）
                    Text("Hello, Liquid Glass")
                        .font(.title)
                        .padding()
                        .glassEffect()
                    
                    
                    Text("Hello, Liquid Glass")
                        .font(.title)
                        .padding()
                        .glassEffect(.clear)
                    

                    Text("Hello, Liquid Glass")
                        .font(.title)
                        .padding()
                        .glassEffect(.clear.tint(.black.opacity(0.4)))
                    
                    
                    
                    Text("Hello, Liquid Glass")
                        .glassEffect(.regular
                            .tint(.orange.opacity(0.7))   // 著色
                            .interactive()                 // 互動反應（按壓縮放、 shimmer、光暈）
                        )
                    
                    
                    
                    Text("Hello, Liquid Glass")
                        .glassEffect(in: .rect(cornerRadius: 16))           // 圓角矩形
                        .glassEffect(in: .circle)
                    //        .glassEffect(in: RoundedRectangle(cornerRadius: .containerConcentric, style: .continuous))  // 與容器完美貼合
                    
                    
                    GlassEffectContainer(spacing: 40.0) {   // spacing 控制融合距離
                        HStack {
                            Image(systemName: "pencil")
                                .frame(width: 60, height: 60)
                                .glassEffect(.regular.interactive())
                            
                            Image(systemName: "eraser.fill")
                                .frame(width: 60, height: 60)
                                .glassEffect(.regular.interactive())
                        }
                    }
                    
                    
                    GlassEffectContainer(spacing: 40) {
                        if isExpanded {
                            Button("Action") { }
                                .glassEffect()
                                .glassEffectID("action", in: namespace)   // 關鍵 ID
                        }
                        
                        Button("Toggle") {
                            withAnimation(.bouncy) {
                                isExpanded.toggle()
                            }
                        }
                        .glassEffect()
                        .glassEffectID("toggle", in: namespace)
                    }
                    
                    
                    Button("Cancel") { }
                        .font(.largeTitle.bold())
                        .buttonStyle(.glass)           // 半透明
                    
                    Button("Save") { }
                        .buttonStyle(.glassProminent)  // 更醒目
                        .tint(.blue)
                    
                    
                    VStack {
                        Text("Glass Card")
                            .font(.title2.bold())
                        // ... 內容
                    }
                    .padding()
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                    
                    
                    Button { } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .glassEffect(.regular.tint(.purple).interactive())
                    .buttonBorderShape(.circle)
                    
                    
                    
                    Text("Glass Text")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .padding()
                        .glassEffect()
                    
                    
//                    Rectangle().frame(height: 500)
                }
            }
        }.navigationTitle("123")
    }
}

#Preview {
    ButtonTest()
}
