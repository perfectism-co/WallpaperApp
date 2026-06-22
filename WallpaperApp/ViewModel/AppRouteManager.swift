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
    var showAd: Bool = false      // 控制全螢幕廣告是否顯示
    var isSubscribed: Bool = false // 模擬使用者的訂閱狀態（如果付費了就不跳廣告）
    
    /// 統一的廣告觸發檢查點
    func tryTriggerAd(force: Bool = false) {
        // 條件一：如果使用者已經訂閱，直接攔截，絕對不跳廣告
        guard !isSubscribed else { return }
        
        // 條件二：如果是強制觸發（例如 App 剛啟動）
        if force {
            print("應顯示廣告")
            showAd = true
            return
        }
        
    }
}

struct RootContainerView: View {
    @State private var routeManager = AppRouteManager()
    // 監聽 App 的生命週期狀態（前景/背景）
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // 下層：主程式（包含三個分頁）
            MainAppLayoutView()
            
            // 上層：全螢幕廣告
            if routeManager.showAd {
                AdvertisementView()
                    .transition(.opacity) // 輕量淡入淡出
            }
        }
        .animation(.easeInOut, value: routeManager.showAd)
        // 💡 觸發點 1：App 一開啟時偵測
        .onAppear {
            routeManager.tryTriggerAd(force: true)
        }
        // 💡 觸發點 2：使用者滑掉 App 去回訊息，再次返回 App 時自訂偵測
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // 從背景返回前景時，進行自訂判斷（例如距離上次觸發超過 1 小時才跳）
                routeManager.tryTriggerAd(force: false)
            }
        }
        // 將管理器注入環境，讓所有分頁及其深層子網頁都能直接存取
        .environment(routeManager)
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
    // 1. 💡 移除原本的 @Bindable var routeManager
    // 如果這一個外殼層本身「不需要」讀寫 Tab 狀態或廣告狀態，這裡甚至不用宣告任何變數！
    
    // 每個 Tab 獨立的導航棧歷史紀錄依舊保留
    @State private var homePath: [HomeRoute] = []
    @State private var discoverPath: [DiscoverRoute] = []
    @State private var settingsPath: [SettingsRoute] = []
    
    // 用於綁定 TabView 的預設選中頁面（改用本地狀態即可，除非你想從外部強迫轉跳 Tab）
    @State private var currentTab: AppTab = .home
    
    var body: some View {
        // 2. 💡 綁定本地的 currentTab
        TabView(selection: $currentTab) {
            
            // ─── 分頁一：桌布首頁 ───
            NavigationStack(path: $homePath) {
                WallpapersView() // 裡面就是你寫的上層標籤與雙排網格
                    .navigationTitle("桌布首頁")
                    .navigationDestination(for: HomeRoute.self) { route in
                        switch route {
                        case .wallpaperDetail(let id):
                            WallpaperDetailView(wallpaperId: id)
                        case .authorProfile(let name):
                            // 這裡可以導向我們剛剛寫的深層作者頁
                            DeepAuthorProfileView(authorName: name)
                        }
                    }
            }
            .tabItem { Label("首頁", systemImage: "photo") }
            .tag(AppTab.home)
            
            // ─── 分頁二：探索頁 ───
            NavigationStack(path: $discoverPath) {
                DiscoverHomeView()
                    .navigationTitle("探索")
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
                SettingsHomeView() // 💡 參數拿掉！讓它自己去獨立檔案抓環境變數
                    .navigationTitle("設定")
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

// ─── 修正 Preview 寫法 ───
#Preview {
    MainAppLayoutView()
        // 💡 關鍵：因為子網頁會去抓環境變數，預覽時必須幫它注入一個假管理器，才不會閃退
        .environment(AppRouteManager())
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
    // 讀取全域路由管理器
    @Environment(AppRouteManager.self) private var routeManager
    
    var body: some View {
        List {
            NavigationLink("隱私權政策", value: SettingsRoute.privacyPolicy)
            NavigationLink("升級高級會員", value: SettingsRoute.accountUpgrade)
            
            Button("觸發自訂廣告") {
                routeManager.tryTriggerAd(force: true)
            }
            .foregroundColor(.red)
        }
    }
}

// ─── 廣告頁面 ───
struct AdvertisementView: View {
    // 讀取全域路由管理器
    @Environment(AppRouteManager.self) private var routeManager
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
            routeManager.tryTriggerAd(force: true)
        }
    }
}


struct DeepAuthorProfileView: View {
    // 不管多深，只要宣告這行就能直接抓到最外層的環境
    @Environment(AppRouteManager.self) private var routeManager
    let authorName: String
    
    var body: some View {
        VStack {
            Text("創作者：\(authorName)")
            
            Button("追蹤創作者") {
                // 💡 觸發點 4：深層互動觸發
                routeManager.tryTriggerAd(force: true)
            }
        }
        .navigationTitle("作者專頁")
    }
}
