//
//  WallpaperHomeView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/20.
//

import SwiftUI

// 1. 定義上方標籤的枚舉
enum WallpaperTag: String, CaseIterable, Identifiable {
    case featured = "Featured"
    case wallpapers = "Wallpapers"
    case summer = "Summer"
    case render3D = "3D Render"
    
    var id: String { self.rawValue }
}

struct WallpaperHomeView: View {
    // 2. 追蹤目前選中的上方標籤
    @State private var selectedSubTag: WallpaperTag = .featured
    // 用於標籤列的滾動定位
    @Namespace private var animationNamespace
    
    var body: some View {
        VStack(spacing: 0) {
            // ─── 頂部左右滑動標籤列 ───
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(WallpaperTag.allCases) { tag in
                            VStack(spacing: 8) {
                                Text(tag.rawValue)
                                    .font(.system(size: 16, weight: selectedSubTag == tag ? .bold : .medium))
                                    .foregroundColor(selectedSubTag == tag ? .primary : .secondary)
                                
                                // 選中時的底部底線指示器
                                if selectedSubTag == tag {
                                    Color.primary
                                        .frame(height: 2)
                                        .matchedGeometryEffect(id: "underline", in: animationNamespace)
                                } else {
                                    Color.clear
                                        .frame(height: 2)
                                }
                            }
                            .id(tag) // 設定 ID 供自動捲動使用
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSubTag = tag
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 44)
                // 當下方滑動換頁時，上方標籤列會自動跟著滾動到可見區域
                .onChange(of: selectedSubTag) { _, newTag in
                    withAnimation {
                        proxy.scrollTo(newTag, anchor: .center)
                    }
                }
            }
            
            Divider()
            
            // ─── 下方可左右滑動的分頁內容 ───
            TabView(selection: $selectedSubTag) {
                // Featured 內容
                WallpaperGridView(tag: "Featured 內容")
                    .tag(WallpaperTag.featured)
                
                // Wallpapers 內容
                WallpaperGridView(tag: "Wallpapers 內容")
                    .tag(WallpaperTag.wallpapers)
                
                // Summer 內容
                WallpaperGridView(tag: "Summer 內容")
                    .tag(WallpaperTag.summer)
                
                // 3D Render 內容
                WallpaperGridView(tag: "3D 內容")
                    .tag(WallpaperTag.render3D)
            }
            // 💡 關鍵條件：將 TabView 改為左右分頁滑動模式，並隱藏原本底部的圓點指示器
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

// ─── 模擬錄影中的雙排網格視圖 ───
struct WallpaperGridView: View {
    let tag: String
    
    // 定義雙排網格佈局
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1...10, id: \.self) { index in
                    // 點擊後依然可以透過原本定義好的 NavigationLink 跳轉
                    NavigationLink(value: HomeRoute.wallpaperDetail(id: "\(tag)_\(index)")) {
                        VStack(alignment: .leading) {
                            // 模擬桌布圖片
                            Color.gray.opacity(0.3)
                                .aspectRatio(0.7, contentMode: .fit)
                                .cornerRadius(8)
                                .overlay(
                                    Text("\(tag) #\(index)")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.secondary),
                                    alignment: .center
                                )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    WallpaperHomeView()
}
