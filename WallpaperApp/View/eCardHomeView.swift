//
//  eCardHomeView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/22.
//

import SwiftUI
import PhotosUI


enum CardType: String, CaseIterable, Identifiable {
    case eCardVer1
    case eCardVer2
    
    // 實作 Identifiable 要求的 id
    var id: String { self.rawValue }
}

struct eCardHomeView: View {
    @State private var isBarHidden = false

    @State private var cardTitle: String = ""
    @State private var cardBodyText: String = ""
    @FocusState private var isTitleFocused: Bool     // 標題專用
    @FocusState private var isBodyFocused: Bool      // 內文專用
    @State private var isShowTextField: Bool = false
    
    @State private var selectedFont: CustomFontOption = FontManager.shared.defaultBodyFont
    @State private var selectedTitleFont: CustomFontOption = FontManager.shared.defaultTitleFont
    let uiImage = UIImage(named: "myImageName")
    @State private var dominantColor: Color = .clear
    

    @State private var selectedCard: CardType = .eCardVer2
    @State private var showCardStyleSettings: Bool = false
    
    // 選擇照片或使用當前桌布
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showDialog = false
    @State private var showPicker = false // 新增一個狀態來控制 Picker
    
    @State private var textHeight: CGFloat = 0 // 儲存文字框高度
    
    
    @State private var selectedTapeColor = TapeColorOption(name: "deep-yellow-tape", hex: "#FFCC00")
    
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
                
                // 3. 根據目前的狀態，決定要渲染哪一張卡片
                renderCard(for: selectedCard)
//                Group {
//                    switch selectedCard {
//                    case .eCardVer1:
//                        eCardVer1
//                        
//                    case .eCardVer2:
//                        eCardVer2
//                    }
//                }
                // 加上一點流暢的切換動畫
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedCard)
                
                // 4. 純按鈕切換邏輯
                Button(action: {
                    showCardStyleSettings = true
                    // 點擊時，在兩種狀態之間切換
//                    selectedCard = (selectedCard == .eCardVer1) ? .eCardVer2 : .eCardVer1
                }) {
                    Text("Change Card Design")
                        .foregroundStyle(Color.init(uiColor: .label))
                        .padding()
                }
                .frame(width: 300)
                .glassEffect()
            
                // 一鍵分享按鈕：每次點擊分享選單彈出時，ShareLink 會動態觸發這個 Image
                ShareLink(
                    item: renderCardToImage(), // 這裡已經是非 Optional 的 Image 了
                    preview: SharePreview("自製桌布", image: renderCardToImage())
                ) {
                    Label("Share Your eCard", systemImage: "square.and.arrow.up")
                        .foregroundStyle(Color.init(uiColor: .label))
                        .padding()
                        .frame(width: 300)
                        .glassEffect()
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
        .fontPickerToolbar(           // ← 自動判斷目前輸入哪一個
            selectedFont: $selectedFont,
            selectedTitleFont: $selectedTitleFont,
            selectedTapeColor: $selectedTapeColor,
            selectedCard: $selectedCard,
            isTitleFocused: $isTitleFocused,
            isBodyFocused: $isBodyFocused
        )
        .onTapGesture {
            isTitleFocused = false
            isBodyFocused = false
        }
        .sheet(isPresented: $showCardStyleSettings) {
            CardStyleSettingView
                .presentationDragIndicator(.visible)
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
    
    // 利用 @ViewBuilder 統一處理 switch 映射
    @ViewBuilder
    private func renderCard(for type: CardType) -> some View {
        switch type {
        case .eCardVer1:
            eCardVer1
        case .eCardVer2:
            eCardVer2
        }
    }
    
    
    // 呼叫純靜態的 SnapshotCard，傳入純數值
    @MainActor
    private func renderCardToImage() -> Image {
        // 1. 宣告為 any View，這樣就能完美兼容 switch 裡不同的 Struct
        let viewToRender: any View
        
        // 2. 完美對齊你的 Enum (不需要 default，讓編譯器幫你檢查是否漏掉)
        switch selectedCard {
        case .eCardVer1:
            viewToRender = SnapshotCard1(
                cardTitle: cardTitle,
                cardBodyText: cardBodyText,
                selectedFont: selectedFont,
                selectedTitleFont: selectedTitleFont,
                uiImage: uiImage,
                dominantColor: dominantColor
            )
        case .eCardVer2:
            viewToRender = SnapshotCard2(
                cardTitle: cardTitle,
                cardBodyText: cardBodyText,
                selectedFont: selectedFont,
                selectedTitleFont: selectedTitleFont,
                uiImage: uiImage,
                dominantColor: dominantColor,
                selectedTapeColor: selectedTapeColor,
                textHeight: textHeight
            )
        }
        
        // 3. 將 any View 包裝成 AnyView 讓 ImageRenderer 讀取
        let renderer = ImageRenderer(content: AnyView(viewToRender))
        
        // 確保在高解析度螢幕（如視網膜螢幕）上的渲染品質
        renderer.scale = 3.0
        
        // 4. 取得圖片並回傳
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        
        // 萬一失敗的降級安全兜底（回傳空白圖片，避免 App 崩潰）
        return Image(uiImage: UIImage())
    }
   
    
//MARK: - CardStyleSetting View
    private var CardStyleSettingView: some View {
        
        VStack {
            Group{
                Text("Card Design")
                    .font(.title)
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                Text("Choose your card design.")
                    .font(.callout)
                    .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 30), // 設定第一個與第二個之間的水平間距
                    GridItem(.flexible(), spacing: 30)  // 左右間距會由這裡的 spacing 決定
                ], spacing: 30) {
                    ForEach(CardType.allCases) { card in
                        // 呼叫下方的輔助函式來決定要渲染哪一張圖
                        Image(card.rawValue)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                selectedCard = card // 點擊卡片自動更新狀態
                                showCardStyleSettings = false
                            }
                    }
                }
            }
        }
        .padding()
       
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
                        if cardTitle.isEmpty {
                            Text("Enter your blessing message")
                                .font(.custom("FlaemischeKanzleischrift", size: 48))
                                .foregroundStyle(Color.white.opacity(0.6))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.clear)
                                .onTapGesture {
                                    isTitleFocused = true
                                }
                        }
                        
                        TextField("", text: $cardTitle, axis: .vertical)
                        .font(selectedTitleFont.targetFont(48))
                        .foregroundStyle(Color.white)
                        .lineLimit(1...3)
                        .padding()
                        .focused($isTitleFocused)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 48)
                    
                    
                    ZStack(alignment: .topLeading) {
                        if cardBodyText.isEmpty {
                           
                            Text("Dear [Name]\n\nSay something...")
                                .foregroundStyle(Color.white.opacity(0.6))
                                .padding(.horizontal, 26)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical)
                                .background(dominantColor)
                                .onTapGesture {
                                    isBodyFocused = true
                                }
                        }
                        
                        TextField("",
                                  text: $cardBodyText,
                                  prompt: Text(""),
                                  axis: .vertical
                        )
                        .font(selectedFont.targetFont(18))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 26)
                        .padding(.vertical)
                        .focused($isBodyFocused)
                    }
                    
                }
                .padding(.bottom, 50)
            }
            
        }
        .background(dominantColor)
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.vertical)
    }
    
    
    private var eCardVer2: some View {
        VStack {
            HStack(spacing: 4) {
                VStack {
                    Text("✨")
                    Spacer()
                }
                Text("This card design allows you to upload your own photo. Tap the photo to upload an image.")
                    .font(.footnote)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
            .frame(width: 300, alignment: .topLeading)
            .background(Color.black.opacity(0.1))
            .cornerRadius(4)
//            .background {
//                // 直接在 .glassEffect 中指定形狀
//                Color.clear.glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
//            }
            
            
           
            ZStack(alignment: .top) {
                // Photo
                Group{
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 300)
                            .clipped()
                            .contentShape(Rectangle())
                    } else {
                        Image(uiImage: uiImage!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 300, height: 300)
                            .clipped()
                            .contentShape(Rectangle())
                    }
                    
                }
                .onTapGesture {
                    showDialog = true
                }
                .confirmationDialog("Choose Photo Type", isPresented: $showDialog, titleVisibility: .visible) {
                    Button("當前手機桌布") {
                        selectedImage = nil
                    }
                        
                    // 這裡改成普通按鈕，點擊後觸發 showPicker
                    Button("上傳照片") {
                        showPicker = true
                    }
                    
                } message: {
                    Text("請選擇來源")
                }
                // 將 PhotosPicker 移出對話框，設為隱藏或透過觸發條件顯示
                .photosPicker(isPresented: $showPicker, selection: $selectedItem, matching: .images)
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                        }
                    }
                }
                
                VStack (spacing: 35) {
                    ZStack {
                        
                        // 色彩膠帶
                        Image(selectedTapeColor.name)
                            .resizable()
                            //.foregroundStyle(selectedTapeColor.color) // 使用 .color 屬性取得 Color 物件
                            .frame(maxWidth: .infinity)
                            .frame(height: textHeight)
                        
                        // 標題
                        if selectedTitleFont == FontManager.shared.titleFontOptions[0] {
                            if cardTitle.isEmpty {
                                Text("Enter your blessing message")
                                    .font(.system(size: 30, weight: .black, design: .default))
                                    .foregroundStyle(Color.black.opacity(0.3))
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .background(Color.clear)
                                    .onTapGesture {
                                        isTitleFocused = true
                                    }
                            }
                            
                            TextField("", text: $cardTitle, axis: .vertical)
                                .font(selectedTitleFont.targetFont(48))
                                .lineLimit(1...3)
                                .focused($isTitleFocused)
                                .foregroundStyle(Color.black.opacity(0.65))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                            // [cite: 35] 關鍵語法：監聽邊界尺寸變化，一旦變動就更新變數
                                .onGeometryChange(for: CGFloat.self, of: { proxy in
                                    proxy.size.height // 鎖定偵測高度
                                }, action: { newValue in
                                    textHeight = newValue + 16 // 同步到狀態變數
                                })
                        }else {
                            // 標題
                            if cardTitle.isEmpty {
                                Text("Enter your blessing\nmessage")
                                    .font(.system(size: 30, weight: .black, design: .default))
                                    .foregroundStyle(Color.black.opacity(0.3))
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .background(Color.clear)
                                    .onTapGesture {
                                        isTitleFocused = true
                                    }
                            }
                            
                            TextField("",text: $cardTitle, axis: .vertical)
                                .font(selectedTitleFont.targetFont(48))
                                .lineLimit(1...3)
                                .focused($isTitleFocused)
                                .foregroundStyle(Color.black.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                            // [cite: 35] 關鍵語法：監聽邊界尺寸變化，一旦變動就更新變數
                                .onGeometryChange(for: CGFloat.self, of: { proxy in
                                    proxy.size.height // 鎖定偵測高度
                                }, action: { newValue in
                                    textHeight = newValue - 24 // 同步到狀態變數
                                })
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    
                    // 內文
                    ZStack(alignment: .topLeading) {
                        if cardBodyText.isEmpty {
                            Text("Dear [Name]\n\nSay something...")
                                .foregroundStyle(Color.black.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .onTapGesture {
                                    isBodyFocused = true
                                }
                        }
                        
                        TextField("", text: $cardBodyText, axis: .vertical)
                        .font(selectedFont.targetFont(18))
                        .foregroundStyle(Color.init(uiColor: .darkGray))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .focused($isBodyFocused)
                    }
                    .padding(.horizontal, 26)
                    
                }
                .alignmentGuide(.top) { d in d[.top] - 294 }
                .padding(.bottom, 50)
                
            }
            .frame(width: 300)
            .background(.white)
            .padding(.vertical)
        }
        
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
