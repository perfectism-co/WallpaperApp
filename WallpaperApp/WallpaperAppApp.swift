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
            RootContainerView()
        }
    }
}


#Preview("有廣告狀態（預設）") {
    RootContainerView()
}

#Preview("無廣告狀態（直接看分頁）") {
    // 如果你的狀態管理允許外部注入初始值
    // 或是直接預覽內層的佈局視圖：
    let fakeManager = AppRouteManager()
    fakeManager.showAd = false // 強制關閉廣告
    
    return MainAppLayoutView(routeManager: fakeManager)
}
