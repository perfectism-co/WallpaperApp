//
//  WallpapersView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/21.
//

import SwiftUI

enum WallpaperTag: String, CaseIterable, Identifiable {
    case featured = "Featured"
    case wallpapers = "Wallpapers"
    case summer = "Summer"
    case render3D = "3D Render"
    
    var id: String { self.rawValue }
}

struct WallpapersView: View {
    @State private var selectedSubTag: WallpaperTag = .featured
    @Namespace private var glassBubbleNamespace
    @State private var showb: Bool = false
    @State private var showc: Bool = false
    let enableScrollableTab = true
        
    var body: some View {
        
        ReusableTabView(
            tabs: WallpaperTag.allCases,
            selectedTab: $selectedSubTag,
            isTabBarScrollable: enableScrollableTab,
            tabTitle: { tab in tab.rawValue } // 告訴套件如何取得每個 Tab 的文字
        ) { tab in
            // 使用 @ViewBuilder 根據目前的 tab 回傳對應的畫面
            switch tab {
            case .featured:
                WallpaperGridView(tag: "Featured內容")
            case .wallpapers:
                WallpaperGridView(tag: "Wallpapers內容")
            case .summer:
                WallpaperGridView(tag: "Summer內容")
            case .render3D:
                WallpaperGridView(tag: "3D Render內容")
            }
        } content2: {
            // 第二個閉包：對應 content2() 的底部置底自訂內容
            VStack {
                Group{
                    Text("Happy Evety Day")
                        .font(.title2).padding(.bottom, 4)
                    Text("這是從外部傳入的 content2 內容 /n wkepw[dsdsfl,l;g;f.hlglf;dh.;'h'g;h,;'cv.h;'vb.g,h;lfg,h;gb,c;glflgh;'gh kdlfk;cg,fgfl;  f;kf;g。 ;fgl;fgk,;xcgff klf;gk;flhk;gf")
                        .font(.callout)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding().padding(.bottom, 20)
        }
        
    }
}

struct WallpaperGridView: View {
    let tag: String
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
    
    var body: some View {
        ZStack{
            Color.clear // 1. 產生一個透明底板，它會精準貼齊當前的可用螢幕範圍
                .overlay(
                    Image("myImageName")
                        .resizable()
                        .scaledToFill() // 圖片在 overlay 裡面無論怎麼放大...
                )
                .clipped() // 2. 強制將疊在上面的圖片，裁切成跟 Color.clear 完全一樣大
                .ignoresSafeArea(.container, edges: .all) // 3. 讓整個組合體延伸到瀏海和底部邊緣
            VStack{
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0), .black.opacity(0.3)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 300)
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0), .black.opacity(0.5)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 550)
            }
            .ignoresSafeArea(.all)
            
            
//                .overlay(
//                    Text("123")
//                        .font(.caption)
//                        .bold()
//                        .foregroundColor(.white) // 建議改為白色或加上陰影以提升在圖片上的辨識度
//                        .padding(4)
//                        .background(Color.black.opacity(0.5)) // 加上半透明黑色底色讓文字更清晰
//                        .cornerRadius(4),
//                    alignment: .center
//                )
        }
        .navigationTitle("Wallpapers")
        .navigationBarTitleDisplayMode(.inline)
        
//        ScrollView(showsIndicators: false) {
//            LazyVGrid(columns: columns, spacing: 10) {
//                ForEach(1...10, id: \.self) { index in
//                    NavigationLink(value: HomeRoute.wallpaperDetail(id: "\(tag)_\(index)")) {
//                        Image("myImageName")
//                            .resizable()
//                            // 1. 設定圖片比例與填充模式
//                            .aspectRatio(0.7, contentMode: .fill)
//                            // 2. 裁切掉超出設定比例的圖片邊緣
//                            .clipped()
//                            // 3. 在最外層加上圓角，確保所有內容都被正確裁切
//                            .cornerRadius(8)
//                            // 4. 若圖片有透明區域，可在此補上灰色背景
//                            .background(Color.gray.opacity(0.3))
//                            // 5. 疊加文字
//                            .overlay(
//                                Text("\(tag) #\(index)")
//                                    .font(.caption)
//                                    .bold()
//                                    .foregroundColor(.white) // 建議改為白色或加上陰影以提升在圖片上的辨識度
//                                    .padding(4)
//                                    .background(Color.black.opacity(0.5)) // 加上半透明黑色底色讓文字更清晰
//                                    .cornerRadius(4),
//                                alignment: .center
//                            )
//                    }
//                }
//            }
//        }
//        .ignoresSafeArea(.container, edges: .all)
    }
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



#Preview {
    // 預覽時必須包裹在 NavigationStack 中，才能正確模擬導航欄穿透效果
    NavigationStack {
        WallpapersView()            
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
    .environment(AppRouteManager())
}

#Preview {
    WallpapersView()
}

