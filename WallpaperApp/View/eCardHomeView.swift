//
//  eCardHomeView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/22.
//

import SwiftUI


struct eCardHomeView: View {
    
    @State private var isBarHidden = false

   
    // 選擇照片或使用當前桌布
    let uiImage = UIImage(named: "myImageName")
 
   
    @State private var dominantColor: Color = .clear
    
    @State private var showCardStyleSettings: Bool = false
    

    var body: some View {
        ZStack {
            Color.clear // 產生一個透明底板，它會精準貼齊當前的可用螢幕範圍
                .overlay(
                    Image("myImageName") // ❇️ 底圖
                        .resizable()
                        .scaledToFill() // 圖片在 overlay 裡面無論怎麼放大...
                )
                .clipped() // 強制將疊在上面的圖片，裁切成跟 Color.clear 完全一樣大
                .ignoresSafeArea(.container, edges: .all) // 讓整個組合體延伸到瀏海和底部邊緣
            
            Color.clear
                .background(.ultraThinMaterial) // ❇️ 模糊遮罩
                .environment(\.colorScheme, .dark)
            
            
            ScrollView(.vertical, showsIndicators: false) {
                Text("Brighten a friend's day with an e-card! Tap the text to write your message.")
                    .frame(width: 300, alignment: .leading)
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                    .environment(\.colorScheme, .dark)
                
                eCardVer1
                
                // 操作鍵
                Button(action: {
                    showCardStyleSettings = true
                }) {
                    Text("Change Card Design")
                        .foregroundStyle(Color.init(uiColor: .label))
                        .padding()
                }
                .frame(width: 300)
                .glassEffect()
                
                
                Button{
                    
                }label: {
                    Text("Edit Card")
                        .foregroundStyle(Color.init(uiColor: .label))
                        .padding()
                }
                .frame(width: 300)
                .glassEffect()
                

                
                
                // 👇 加入這段測試用的高度佔位符，把頁面撐開！
                ForEach(0..<20) { i in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 150)
                        .overlay(Text("未來要放的桌布內容 \(i)").foregroundColor(.white))
                        .padding(.horizontal)
                }
            
            }
            .navigationTitle("eCard").foregroundStyle(Color.white)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            // 滾動偵測
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

        .sheet(isPresented: $showCardStyleSettings) {
           
        }
        .onAppear {
            Task {
                // 當圖片改變時，非同步計算最大面積顏色
                dominantColor = await uiImage!.getDominantColor()
            }
            // 載入時取得顏色 (如果是動態載入，這裡可以更新)
//            dominantColor = getDominantColor(from: uiImage!)
//            let rawColor = getDominantColor(from: uiImage!)
//            
//            // 2. 丟進你的獨立管理器進行「咖啡色攔截」與「未來其他顏色校正」
//            dominantColor = ColorThemeManager.adjustDominantColor(rawColor)
        }
    }

    
    
// MARK: - 卡片設計
    
    private var eCardVer1: some View {
       
        VStack {
            ZStack(alignment: .top) {
                
                Image(uiImage: uiImage!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .clipped()
                               
                // 顏色漸層遮罩
                ZStack(alignment: .bottom) {
                    Color.clear.frame(width: 300, height: 300)
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [dominantColor.opacity(0), dominantColor.opacity(1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                }
                
                // 文字
                VStack(spacing: 0) {
                    Color.clear.frame(width: 300, height: 250)
                    ZStack {
                        Text("Have a Wonderful Day")
                            .font(.custom("FlaemischeKanzleischrift", size: 48))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .blendMode(.plusLighter)
                            .padding()
                        
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 48)
                    
                    
                    ZStack(alignment: .topLeading) {
                        Text("Dear Liam, \n\nJust a little note to remind you that you're appreciated. I hope today brings you happiness, smiles, and many wonderful moments.\n\nBest wishes,\nSophia")
                            .font(.custom("System", size: 18))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .blendMode(.plusLighter)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 26)
                            .padding(.vertical)
                       
                    }
                    .padding(.bottom, 50)
                }
                
            }
            
        }
//        .background(dominantColor)
        .background{
            ZStack {
                Rectangle()
                    .fill(dominantColor)
                VStack {
                    Color.clear.frame(width: 300, height: 300)
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [dominantColor.opacity(0), Color.black.opacity(0.15)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(maxWidth: .infinity)
                }
            }
            
        }
        .task(id: uiImage) {
            // 當圖片改變時，非同步計算最大面積顏色
            dominantColor = await uiImage!.getDominantColor()
        }
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.vertical)
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




extension Color {
    // 🎯 最新標準：WCAG 相對亮度計算 (Gamma-corrected)
    var relativeLuminance: Double {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        // 進行 Gamma 校正
        let rC = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4)
        let gC = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4)
        let bC = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4)

        // 回傳標準相對亮度
        return 0.2126 * rC + 0.7152 * gC + 0.0722 * bC
    }

    func foregroundColorForBackground() -> Color {
        // 💡 WCAG 官方定義白/黑字的切換閾值通常在 0.179
        // 為了確保你的 #e6589b (相對亮度約 0.26) 能顯示白字，我們將視覺門檻稍微提高到 0.3
        return self.relativeLuminance > 0.45 ? .black.opacity(0.75) : .white.opacity(0.8)
    }
}



// MARK: - 暫時用不到
struct CategoryListView: View {
    let categoryType: String
    var body: some View {
        Text("這裡全是 \(categoryType) 的桌布列表")
            .navigationTitle(categoryType)
    }
}



//NavigationLink("動漫風格", value: eCardRoute.categoryList(type: "Anime"))
//NavigationLink("風景寫實", value: eCardRoute.categoryList(type: "Landscape"))
//Text("123").font(.largeTitle.bold())
