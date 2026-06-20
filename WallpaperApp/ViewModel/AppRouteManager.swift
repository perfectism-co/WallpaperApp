//
//  File.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/20.
//

import SwiftUI

// 1. 定義底部三個分頁的枚舉
enum AppTab {
    case home
    case discover
    case settings
}

// 2. 建立一個全局或局部管理的狀態（使用現代 @Observable 宏）
@Observable
class AppRouteManager {
    var currentTab: AppTab = .home
    var showAd: Bool = true // 控制廣告是否顯示，預設一開始使用時為 true
    
    // 自訂判斷邏輯：例如從背景返回、或特定事件觸發時再次顯示廣告
    func triggerAdConditional() {
        // 這裡可以寫你的自訂判斷，滿足條件才執行
        let shouldShow = true
        if shouldShow {
            showAd = true
        }
    }
}

struct RootContainerView: View {
    // 3. 宣告路由管理器
    @State private var routeManager = AppRouteManager()
    
    var body: some View {
        ZStack {
            // ─── 第一層：主程式內容（底部 Toolbar 系統） ───
            MainAppLayoutView(routeManager: routeManager)
            
            // ─── 第二層：覆蓋型廣告頁 ───
            // 使用 if 條件判斷，當條件滿足時，直接覆蓋在最上層
            if routeManager.showAd {
                AdvertisementView(routeManager: routeManager)
                    // 加入流暢的淡入淡出動畫
                    .transition(.opacity)
            }
        }
        // 確保狀態改變時的動畫效果
        .animation(.easeInOut, value: routeManager.showAd)
    }
}



// ─── 1. 定義各分頁專屬的路由枚舉（皆須符合 Hashable） ───
enum HomeRoute: Hashable {
    case wallpaperDetail(id: String)
    case authorProfile(name: String)
}

enum DiscoverRoute: Hashable {
    case categoryList(type: String)
}

enum SettingsRoute: Hashable {
    case privacyPolicy
    case accountUpgrade
}

// ─── 2. 主程式佈局（三個頁面 + 獨立導航棧） ───
struct MainAppLayoutView: View {
    @Bindable var routeManager: AppRouteManager
    
    // 為每個 Tab 宣告獨立的 Path 狀態，用以精確控制該分頁的返回歷史
    @State private var homePath: [HomeRoute] = []
    @State private var discoverPath: [DiscoverRoute] = []
    @State private var settingsPath: [SettingsRoute] = []
    
    var body: some View {
        TabView(selection: $routeManager.currentTab) {
            
            // ─── 分頁一：桌布首頁 ───
            NavigationStack(path: $homePath) {
                WallpaperHomeView()
                    .navigationTitle("桌布首頁")
                    // 攔截分頁一的路由
                    .navigationDestination(for: HomeRoute.self) { route in
                        switch route {
                        case .wallpaperDetail(let id):
                            WallpaperDetailView(wallpaperId: id)
                        case .authorProfile(let name):
                            AuthorProfileView(name: name)
                        }
                    }
            }
            .tabItem { Label("首頁", systemImage: "photo") }
            .tag(AppTab.home)
            
            // ─── 分頁二：探索頁 ───
            NavigationStack(path: $discoverPath) {
                DiscoverHomeView()
                    .navigationTitle("探索")
                    // 攔截分頁二的路由
                    .navigationDestination(for: DiscoverRoute.self) { route in
                        switch route {
                        case .categoryList(let type):
                            CategoryListView(categoryType: type)
                        }
                    }
            }
            .tabItem { Label("探索", systemImage: "magnifyingglass") }
            .tag(AppTab.discover)
            
            // ─── 分頁三：設定頁 ───
            NavigationStack(path: $settingsPath) {
                SettingsHomeView(routeManager: routeManager)
                    .navigationTitle("設定")
                    // 攔截分頁三的路由
                    .navigationDestination(for: SettingsRoute.self) { route in
                        switch route {
                        case .privacyPolicy:
                            Text("隱私權條款內容...")
                        case .accountUpgrade:
                            Text("升級會員界面")
                        }
                    }
            }
            .tabItem { Label("設定", systemImage: "gearshape") }
            .tag(AppTab.settings)
        }
    }
}

// ─── 三、 各分頁內部的視圖實作與跳轉語法 ───

// 【分頁一的內容】
//struct WallpaperHomeView: View {
//    var body: some View {
//        VStack(spacing: 20) {
//            // 使用 NavigationLink 並帶入 value
//            NavigationLink("點擊查看 4K 貓咪桌布", value: HomeRoute.wallpaperDetail(id: "cat_4k"))
//            NavigationLink("查看創作者 Alex", value: HomeRoute.authorProfile(name: "Alex"))
//        }
//    }
//}

struct WallpaperDetailView: View {
    let wallpaperId: String
    var body: some View {
        VStack {
            Text("桌布 ID: \(wallpaperId)")
                .font(.title)
            // 這裡可以繼續往下推：點擊作者名字，跳轉到作者頁面
            NavigationLink("查看此桌布作者", value: HomeRoute.authorProfile(name: "貓咪大師"))
        }
        .navigationTitle("桌布詳情")
    }
}

struct AuthorProfileView: View {
    let name: String
    var body: some View {
        Text("創作者 \(name) 的個人主頁")
            .navigationTitle(name)
    }
}

// 【分頁二的內容】
struct DiscoverHomeView: View {
    var body: some View {
        List {
            NavigationLink("動漫風格", value: DiscoverRoute.categoryList(type: "Anime"))
            NavigationLink("風景寫實", value: DiscoverRoute.categoryList(type: "Landscape"))
        }
    }
}

struct CategoryListView: View {
    let categoryType: String
    var body: some View {
        Text("這裡全是 \(categoryType) 的桌布列表")
            .navigationTitle(categoryType)
    }
}

// 【分頁三的內容】
struct SettingsHomeView: View {
    var routeManager: AppRouteManager
    var body: some View {
        List {
            NavigationLink("隱私權政策", value: SettingsRoute.privacyPolicy)
            NavigationLink("升級高級會員", value: SettingsRoute.accountUpgrade)
            
            Button("觸發自訂廣告") {
                routeManager.triggerAdConditional()
            }
            .foregroundColor(.red)
        }
    }
}

// ─── 廣告頁面 ───
struct AdvertisementView: View {
    var routeManager: AppRouteManager
    @State private var countdown = 5 // 廣告倒數計時
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // 廣告通常為全螢幕背景
            
            VStack {
                HStack {
                    Spacer()
                    // 跳過廣告按鈕
                    Button(action: {
                        routeManager.showAd = false // 關閉廣告，直接露出底層的 TabView
                    }) {
                        Text("跳過 \(countdown)s")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .padding()
                }
                
                Spacer()
                
                Text("這是蓋台廣告內容")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()
                
                Spacer()
            }
        }
        .onAppear {
            // 模擬倒數計時自動關閉
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if countdown > 1 {
                    countdown -= 1
                } else {
                    timer.invalidate()
                    routeManager.showAd = false // 倒數結束自動關閉
                }
            }
        }
    }
}

// ─── 其他分頁的 Placeholder ───
struct PageOneView: View { var body: some View { Text("頁面一內容") } }
struct PageTwoView: View { var body: some View { Text("頁面二內容") } }
struct PageThreeView: View {
    var routeManager: AppRouteManager
    var body: some View {
        Button("手動觸發廣告（模擬自訂判斷）") {
            routeManager.triggerAdConditional()
        }
    }
}
