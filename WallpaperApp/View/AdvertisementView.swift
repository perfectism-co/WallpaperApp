//
//  AdvertisementView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/22.
//

import SwiftUI

struct AdvertisementView: View {
    // 讀取全域路由管理器
    @Environment(AppRouteManager.self) private var routeManager
//    @State private var countdown = 5 // 廣告倒數計時
    
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
//                        Text("跳過 \(countdown)s")
                        Text("跳過")
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
//        .onAppear {
//            // 模擬倒數計時自動關閉
//            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
//                if countdown > 1 {
//                    countdown -= 1
//                } else {
//                    timer.invalidate()
//                    routeManager.showAd = false // 倒數結束自動關閉
//                }
//            }
//        }
    }
}


#Preview {
    AdvertisementView()
        .environment(AppRouteManager())
}
