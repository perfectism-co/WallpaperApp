//
//  WallpaperAppApp.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/20.
//

import SwiftUI

@main
struct WallpaperAppApp: App {
    var body: some Scene {
        WindowGroup {
            RootContainerView() // 這是 App 的真正進入點（內部已包含環境注入）

        }
    }
}

// ─── 預覽區 ───

#Preview("完整啟動流程（一開始有廣告）") {
    RootContainerView()
}

#Preview("無廣告狀態") {
    // 1. 建立一個專屬於這個預覽的管理器
    let previewManager = AppRouteManager()
    
    // 2. 為了讓你「直接看到三個分頁」，我們將 showAd 預設改為 false
    previewManager.showAd = false
    
    // 3. 根據你的需求：只檢查是否訂閱。這裡設定為訂閱 (true)
    previewManager.isSubscribed = true
    
    // 4. 💡 關鍵：不要直接返回 MainAppLayoutView，而是返回 RootContainerView 的外殼
    // 但因為 RootContainerView 內部自己有用 @State 宣告一個全域的 manager 蓋過去了，
    // 為了讓外面的 previewManager 能夠控制它，最標準的預覽測試寫法是：
    return RootContainerView_PreviewWrapper(manager: previewManager)
}

// ─── 為了完美支援 Canvas 互動的預覽輔助容器 ───
struct RootContainerView_PreviewWrapper: View {
    let manager: AppRouteManager
    
    var body: some View {
        ZStack {
            MainAppLayoutView()
            
            if manager.showAd {
                AdvertisementView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: manager.showAd)
        .environment(manager) // 將被修改過初始狀態的 manager 注入環境
    }
}
