//
//  test2.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/24.
//

import SwiftUI

struct test2: View {
    @State private var isBarHidden = false
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(0..<30) { i in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.15))
                                .frame(height: 250)
                                .overlay(Text("桌布預覽 \(i)"))
                                .padding(.horizontal)
                        }
                    }
                }
                .navigationTitle("選擇桌布")
                .navigationBarTitleDisplayMode(.inline) // 固定小標題
                
                // 💡 iOS 18 新增的滾動幾何偵測
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y // 抓取 y 軸滾動距離
                } action: { oldValue, newValue in
                    // newValue > oldValue 代表頁面正在「往下滑動」（內容往上跑）
                    if newValue > 100 && newValue > oldValue {
                        if !isBarHidden {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isBarHidden = true
                            }
                        }
                    } else if newValue < oldValue {
                        // 往上滑動（內容往下跑）時，重新顯示導覽列
                        if isBarHidden {
                            withAnimation(.easeIn(duration: 0.2)) {
                                isBarHidden = false
                            }
                        }
                    }
                }
                // 動態切換隱藏或顯示
                .toolbar(isBarHidden ? .hidden : .visible, for: .navigationBar)
            }
        }
}

#Preview {
    test2()
}
