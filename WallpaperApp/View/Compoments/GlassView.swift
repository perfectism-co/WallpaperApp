//
//  GlassView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/24.
//

import SwiftUI

struct GlassView: View {
    var body: some View {
        ZStack {
            // 背景圖片
            Image("myImageName")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // 模糊卡片
            Color.clear
                .background(.ultraThinMaterial) // 使用超薄磨砂玻璃效果
                
        }
    }
}

#Preview {
    GlassView()
}
