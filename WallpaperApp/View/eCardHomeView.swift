//
//  eCardHomeView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/22.
//

import SwiftUI

// 【分頁二的內容】
struct eCardHomeView: View {
    var body: some View {
        ZStack{
            
            ScrollView {
                NavigationLink("動漫風格", value: eCardRoute.categoryList(type: "Anime"))
                NavigationLink("風景寫實", value: eCardRoute.categoryList(type: "Landscape"))
                Text("123").font(.largeTitle.bold())
                Image("myImageName").resizable()
            }
            .navigationTitle("eCard")
            .navigationBarTitleDisplayMode(.inline)
            
            
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

#Preview {
    // 1. 必須加上導航棧外殼，Canvas 的點擊跳轉機制才能運作
    NavigationStack {
        eCardHomeView()
            // 2. 必須在 Stack 內部掛載攔截點，指定收到 eCardRoute 時該去哪一頁
            .navigationDestination(for: eCardRoute.self) { route in
                switch route {
                case .categoryList(let type):
                    CategoryListView(categoryType: type)
                }
            }
    }
    // 3. 注入你的環境變數管理類別
    .environment(AppRouteManager())
}
