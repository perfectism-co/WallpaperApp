//
//  Test.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/24.
//

import SwiftUI

struct Test: View {
    @State private var isBarHidden = false
        
        var body: some View {
            ZStack(alignment: .top) {
                // 1. 底層的滾動內容（讓它排滿整個螢幕，包含頂部不留白）
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(0..<30) { i in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.15))
                                .frame(height: 250)
                                .overlay(Text("桌布預覽 \(i)"))
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 70) // 手動留出上方自訂導覽列的高度
                }
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y
                } action: { old, new in
                    if new > 50 && new > old {
                        withAnimation(.easeInOut(duration: 0.25)) { isBarHidden = true }
                    } else if new < old {
                        withAnimation(.easeInOut(duration: 0.25)) { isBarHidden = false }
                    }
                }
                
                // 2. 上層自訂的導覽列（滑動時可完美搭配 Apple 原生毛玻璃）
                if !isBarHidden {
                    HStack {
                        Text("選擇桌布")
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(.ultraThinMaterial) // 精緻的毛玻璃效果
                    .transition(.move(edge: .top).combined(with: .opacity)) // 優雅的滑出與淡出
                }
            }
            //.ignoresSafeArea(edges: .all) // 讓內容與自訂 Bar 都能融入頂部瀏海區
        }
}

#Preview {
    Test()
}
