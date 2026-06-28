//
//  eCardHomeView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/22.
//

import SwiftUI


struct eCardHomeView: View {
    @State private var isBarHidden = false
    @State private var isUploadPage = false
    @State private var cardTitle: String = ""
    @State private var cardBodyText: String = ""
    @FocusState private var isTitleFocused: Bool     // 標題專用
    @FocusState private var isBodyFocused: Bool      // 內文專用
    
    @State private var selectedFont: CustomFontOption = FontManager.shared.defaultFont
    @State private var selectedTitleFont: CustomFontOption = FontManager.shared.defaultFont
    let uiImage = UIImage(named: "myImageName")
    @State private var dominantColor: Color = .clear
    
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
            
            
            ScrollView {
                ZStack{
                    
                    VStack {
                        Color.clear.frame(height: 43)
                        // 1. 畫面預覽：將所有狀態傳入獨立 struct（使用 $ 傳遞 FocusState 的 Binding）
                        eCardVer1
                    }
                    
                    VStack { // ❇️ Header bar
                        HStack(spacing: 0) {
                            Button(action: { isUploadPage = false }) {
                                Text("Current Wallpaper")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(isUploadPage ? Color.clear : Color.white.opacity(0.2))
                                    .clipShape(Capsule()) // 保留內層膠囊
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { isUploadPage = true }) {
                                Text("Upload Photo")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(isUploadPage ? Color.white.opacity(0.2) : Color.clear)
                                    .clipShape(Capsule()) // 保留內層膠囊
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(4) // 💡 關鍵：給予 4 points 的內邊距
                        .foregroundColor(.white)
                        .font(.footnote)
                        .frame(width: 320, height: 43) // 💡 關鍵：外層高度提高 (35 + 4 + 4 = 43)，這樣內層按鈕依然維持 35 的高度
                        .glassEffect(.clear.tint(.black.opacity(0.3)))
                        .clipShape(Capsule())
                        
                        Spacer()
                    }
                    
                    
                }
            
                
                // 👇 加入這段測試用的高度佔位符，把頁面撐開！
                ForEach(0..<20) { i in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 150)
                        .overlay(Text("未來要放的桌布內容 \(i)").foregroundColor(.white))
                        .padding(.horizontal)
                }
                
            
            }
            .navigationTitle("eCard")
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
        .fontPickerToolbar(           // ← 自動判斷目前輸入哪一個
            selectedFont: $selectedFont,
            selectedTitleFont: $selectedTitleFont,
            isTitleFocused: $isTitleFocused,
            isBodyFocused: $isBodyFocused
        )
        .onTapGesture {
            isTitleFocused = false
            isBodyFocused = false
        }
        .onAppear {
            // 載入時取得顏色 (如果是動態載入，這裡可以更新)
            dominantColor = getDominantColor(from: uiImage!)
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
                VStack (spacing: 0) {
                    Color.clear.frame(width: 300, height: 150)
                    
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [dominantColor.opacity(0), dominantColor.opacity(1)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                    }
                }
                
                // 文字
                VStack(spacing: 0) {
                    Color.clear.frame(width: 300, height: 270)
                    ZStack(alignment: .top) {
                        if cardTitle.isEmpty {
                            Text("Enter your blessing\nmessage")
                                .font(.custom("FlaemischeKanzleischrift", size: 38))
                        }
                        
                        TextField("",
                                  text: $cardTitle,
                                  prompt: Text(""),
                                  axis: .vertical
                        )
                        .font(selectedTitleFont.targetFont(28))
                        .lineLimit(1...2)
                        .focused($isTitleFocused)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.bottom, 48)
                    
                    
                    ZStack(alignment: .topLeading) {
                        if cardBodyText.isEmpty {
                            Text("Dear [Name]\n\nSay something...")
                                .foregroundColor(.white.opacity(0.6))
                                .padding()
                        }
                        
                        TextField("",
                                  text: $cardBodyText,
                                  prompt: Text("")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 18, weight: .light)),
                                  axis: .vertical
                        )
                        .font(selectedFont.targetFont(18))
                        .foregroundColor(.white)
                        .padding()
                        .focused($isBodyFocused)
                    }
                    
                }
                
            }
            
        }
        .background(dominantColor)
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





// MARK: - 獨立抽離的 eCardVer1 結構
struct eCardVer1: View {
    // 透過 Binding 讓子元件與父層輸入框即時同步
    @Binding var cardTitle: String
    @Binding var cardBodyText: String
    
    // 字型與顏色直接帶入快照值
    var selectedFont: CustomFontOption
    var selectedTitleFont: CustomFontOption
    var dominantColor: Color
    
    // 處理輸入框焦點
    var isTitleFocused: FocusState<Bool>.Binding
    var isBodyFocused: FocusState<Bool>.Binding
    
    var uiImage: UIImage?
    
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                Image(uiImage: uiImage!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .clipped()

                // 顏色漸層遮罩
                VStack (spacing: 0) {
                    Color.clear.frame(width: 300, height: 150)

                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [dominantColor.opacity(0), dominantColor.opacity(1)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                    }
                }

                // 文字
                VStack(spacing: 0) {
                    Color.clear.frame(width: 300, height: 270)
                    ZStack(alignment: .top) {
                        if cardTitle.isEmpty {
                            Text("Enter your blessing\nmessage")
                                .font(.custom("FlaemischeKanzleischrift", size: 38))
                        }

                        TextField("",
                                  text: $cardTitle,
                                  prompt: Text(""),
                                  axis: .vertical
                        )
                        .font(selectedTitleFont.targetFont(28))
                        .lineLimit(1...2)
                        .focused(isTitleFocused)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.bottom, 48)


                    ZStack(alignment: .topLeading) {
                        if cardBodyText.isEmpty {
                            Text("Dear [Name]\n\nSay something...")
                                .foregroundColor(.white.opacity(0.6))
                                .padding()
                        }

                        TextField("",
                                  text: $cardBodyText,
                                  prompt: Text("")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 18, weight: .light)),
                                  axis: .vertical
                        )
                        .font(selectedFont.targetFont(18))
                        .foregroundColor(.white)
                        .padding()
                        .focused(isBodyFocused)
                    }

                }

            }

        }
        .background(dominantColor)
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.vertical)
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
