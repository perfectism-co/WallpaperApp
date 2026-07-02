//////
//////  SwiftUIView.swift
//////  WallpaperApp
//////
//////  Created by macmini on 2026/6/25.
//////
////
////import SwiftUI
////
////// 1. 定義字型模型（支援自訂字型與系統字型）
////struct CustomFontOption: Identifiable, Equatable {
////    let id = UUID()
////    let displayName: String
////    let fontName: String // 如果是系統內建或專案載入的字型名稱
////    let displayFont: Font // 用於選擇器按鈕上呈現該字型特色
////    let targetFont: (CGFloat) -> Font // 根據輸入框大小動態生成的 Font
////    
////    
////    // 只比較有意義的欄位（通常 fontName 或 displayName 就夠了）
////    static func == (lhs: CustomFontOption, rhs: CustomFontOption) -> Bool {
////        lhs.id == rhs.id ||
////        lhs.fontName == rhs.fontName
////    }
////}
////
////struct IGTextEditorView: View {
////    @State private var text: String = "輸入你的限時動態..."
////    @FocusState private var isInputFocused: Bool
////    
////    // 2. 準備字型清單 (請確保你的專案 Info.plist 已正確載入對應的 ttf/otf 檔案)
////    let fontOptions: [CustomFontOption] = [
////        CustomFontOption(displayName: "標準", fontName: "System", displayFont: .system(.body, design: .default), targetFont: { .system(size: $0, weight: .bold, design: .default) }),
////        CustomFontOption(displayName: "calligraphy", fontName: "FlaemischeKanzleischrift", displayFont: .custom("FlaemischeKanzleischrift", size: 14), targetFont: { .custom("FlaemischeKanzleischrift", size: $0) }),
////        CustomFontOption(displayName: "bold handwriting", fontName: "Big-Snow", displayFont: .custom("Big-Snow", size: 14), targetFont: { .custom("Big-Snow", size: $0) }),
////        CustomFontOption(displayName: "辰宇落雁", fontName: "ChenYuluoyan-2.0-Thin", displayFont: .custom("ChenYuluoyan-2.0-Thin", size: 14), targetFont: { .custom("ChenYuluoyan-2.0-Thin", size: $0) }),
////        CustomFontOption(displayName: "中文手寫粗體", fontName: "StarPandaKidsBeta2.1", displayFont: .custom("StarPandaKidsBeta2.1", size: 14), targetFont: { .custom("StarPandaKidsBeta2.1", size: $0) })
////    ]
////    
////    @State private var selectedFont: CustomFontOption
////    
////    init() {
////        // 預設為第一個字型
////        let defaultFont = CustomFontOption(displayName: "標準", fontName: "System", displayFont: .system(.body, design: .default), targetFont: { .system(size: $0, weight: .bold, design: .default) })
////        _selectedFont = State(initialValue: defaultFont)
////    }
////    
////    var body: some View {
////        ZStack {
////            // 背景（通常是照片或漸層，此處以深色背景示範）
////            Color.black.ignoresSafeArea()
////            
////            // 3. 文字編輯主體
////            TextField("", text: $text, axis: .vertical)
////                .font(selectedFont.targetFont(36)) // 動態套用使用者選中的大字型
////                .foregroundColor(.white)
////                .multilineTextAlignment(.center)
////                .padding()
////                .focused($isInputFocused)
////                .frame(maxWidth: .infinity, alignment: .center)
////        }
////        // 4. 利用 iOS 26 最標準的鍵盤附加視圖（附著在鍵盤正上方）
////        .safeAreaInset(edge: .bottom) {
////            if isInputFocused {
////                fontPickerToolbar
////                    .transition(.move(edge: .bottom).combined(with: .opacity))
////            }
////        }
////        .onAppear {
////            isInputFocused = true // 進入頁面自動彈起鍵盤
////        }
////        .onTapGesture {
////            isInputFocused = false // 點擊空白處，解除焦點，收起鍵盤
////        }
////    }
////    
////    // 5. 橫向滾動字型選擇器
////    private var fontPickerToolbar: some View {
////        VStack(spacing: 0) {
////            ScrollView(.horizontal, showsIndicators: false) {
////                HStack(spacing: 12) {
////                    ForEach(fontOptions) { option in
////                        Button {
////                            selectedFont = option
////                        } label: {
////                            Text(option.displayName)
////                                .font(option.displayFont)
////                                .foregroundColor(selectedFont == option ? .black : .white)
////                                .padding(.horizontal, 16)
////                                .padding(.vertical, 8)
////                                .background(
////                                    selectedFont == option ? Color.white : Color.white.opacity(0.15)
////                                )
////                                .clipShape(Capsule())
////                        }
////                        // 切換字型時給予 iOS 輕微的觸覺震動回饋
////                        .sensoryFeedback(.selection, trigger: selectedFont)
////                    }
////                }
////                .padding(.horizontal, 16)
////                .padding(.vertical, 10)
////            }
////            // 6. 套用 iOS 26 的「液態玻璃」材質做為工具列背景，極具現代感
////            .glassEffect()
////        }
////    }
////}
////
////
//
//
////import SwiftUI
////
////
////struct IGTextEditorView: View {
////    @State private var text: String = "輸入你的限時動態..."
////    @FocusState private var isInputFocused: Bool     // 保持不變
////    
////    @State private var selectedFont: CustomFontOption = FontManager.shared.defaultFont
////    
////    var body: some View {
////        ZStack {
////            Color.black.ignoresSafeArea()
////            
////            TextField("", text: $text, axis: .vertical)
////                .font(selectedFont.targetFont(36))
////                .foregroundColor(.white)
////                .multilineTextAlignment(.center)
////                .padding()
////                .focused($isInputFocused)
////                .frame(maxWidth: .infinity, alignment: .center)
////        }
////        .fontPickerToolbar(
////            selectedFont: $selectedFont,
////            isFocused: $isInputFocused      // 現在可以直接傳入
////        )
////        .onAppear {
////            isInputFocused = true
////        }
////        .onTapGesture {
////            isInputFocused = false
////        }
////    }
////}
////
////
////#Preview {
////    IGTextEditorView()
////}
//
//
//
//import SwiftUI
//
//// 1. 維持獨立的 View，確保自訂字型在離屏渲染時資料鎖死
//struct WallpaperRenderCard: View {
//    let text: String
//    let fontName: String
//    
//    var body: some View {
//        ZStack {
//            Color.pink // 你的背景色
//            
//            Text(text)
//                // 這裡填寫你確認過在 Info.plist 註冊過的 PostScript 名稱
//                .font(.custom(fontName, size: 40))
//                .foregroundStyle(Color.white)
//                .multilineTextAlignment(.center)
//                .padding()
//        }
//        // 這裡給定明確的物理渲染尺寸（標準 iPhone 輸出解析度）
//        .frame(width: 300, height: 600)
//    }
//}
//
//
//struct WallpaperRenderCard2: View {
//    @Binding var cardTitle: String
//    @Binding var cardBodyText: String
//    @FocusState private var isTitleFocused: Bool     // 標題專用
//    @FocusState private var isBodyFocused: Bool      // 內文專用
//    
//    @Binding var selectedFont: CustomFontOption
//    @Binding var selectedTitleFont: CustomFontOption
//   
//    
//    var body: some View {
//        ZStack {
//            Color.brown // 你的背景色
//            
//            VStack(spacing: 0) {
//                
//                ZStack(alignment: .top) {
//                    if cardTitle.isEmpty {
//                        Text("Enter your blessing\nmessage")
//                            .font(.custom("FlaemischeKanzleischrift", size: 38))
//                    }
//                    
//                    TextField("",
//                              text: $cardTitle,
//                              prompt: Text(""),
//                              axis: .vertical
//                    )
//                    .font(selectedTitleFont.targetFont(28))
//                    .lineLimit(1...2)
//                    .focused($isTitleFocused)
//                }
//                .multilineTextAlignment(.center)
//                .foregroundStyle(Color.white)
//                .padding(.horizontal)
//                .padding(.bottom, 48)
//                
//                
//                ZStack(alignment: .topLeading) {
//                    if cardBodyText.isEmpty {
//                        Text("Dear [Name]\n\nSay something...")
//                            .foregroundColor(.white.opacity(0.6))
//                            .padding()
//                    }
//                    
//                    TextField("",
//                              text: $cardBodyText,
//                              prompt: Text("")
//                        .foregroundStyle(Color.white.opacity(0.8))
//                        .font(.system(size: 18, weight: .light)),
//                              axis: .vertical
//                    )
//                    .font(selectedFont.targetFont(18))
//                    .foregroundStyle(Color.white)
//                    .padding()
//                    .focused($isBodyFocused)
//                }
//                
//            }
//        }
//        .fontPickerToolbar(           // ← 自動判斷目前輸入哪一個
//            selectedFont: $selectedFont,
//            selectedTitleFont: $selectedTitleFont,
//            isTitleFocused: $isTitleFocused,
//            isBodyFocused: $isBodyFocused
//        )
//        .onTapGesture {
//            isTitleFocused = false
//            isBodyFocused = false
//        }
//        // 這裡給定明確的物理渲染尺寸（標準 iPhone 輸出解析度）
//        .frame(width: 300, height: 300)
//    }
//    
////    // 新增：專門給 ImageRenderer 使用的初始化方法（避免 Binding 問題）
////        init(cardTitle: String,
////             cardBodyText: String,
////             selectedFont: CustomFontOption,
////             selectedTitleFont: CustomFontOption) {
////            
////            self._cardTitle = .constant(cardTitle)
////            self._cardBodyText = .constant(cardBodyText)
////            self._selectedFont = .constant(selectedFont)
////            self._selectedTitleFont = .constant(selectedTitleFont)
////        }
//}
//
//
//struct FontWallpaperShareView: View {
////    @State private var userText: String = "請輸入"
////    @State private var selectedFontName: String = "Big-Snow"
//    
//    
//    @State private var cardTitle: String = ""
//    @State private var cardBodyText: String = ""
//    
//    @State private var selectedFont: CustomFontOption = FontManager.shared.defaultBodyFont
//    @State private var selectedTitleFont: CustomFontOption = FontManager.shared.defaultTitleFont
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            
//            // 畫面上顯示給用戶看的即時編輯視圖（縮放比例顯示）
////            WallpaperRenderCard(text: userText, fontName: selectedFontName)
////                .aspectRatio(300/300, contentMode: .fit)
////                .frame(height: 400)
////                .cornerRadius(12)
//            
//            WallpaperRenderCard2(
//                cardTitle: $cardTitle,
//                cardBodyText: $cardBodyText,
//                selectedFont: $selectedFont,
//                selectedTitleFont: $selectedTitleFont
//            )
//            
//            
//            // 2. 一鍵分享按鈕：每次點擊分享選單彈出時，ShareLink 會動態觸發這個 Image
//            ShareLink(
//                item: renderCardToImage(),
//                preview: SharePreview("自製桌布", image: renderCardToImage())
//            ) {
//                Label("一鍵分享圖片", systemImage: "square.and.arrow.up")
//                    .font(.headline)
//                    .foregroundStyle(Color.white)
//                    .padding()
//                    .background(Color.blue)
//                    .clipShape(Capsule())
//            }
//        }
//        .padding()
//    }
//    
//    // 3. 核心修正方法：呼叫純靜態的 SnapshotCard，傳入純數值
//        @MainActor
//        private func renderCardToImage() -> Image {
//            // 改為調用純靜態、無互動元件的 Snapshot View
//            let cardToRender = WallpaperSnapshotCard(
//                cardTitle: cardTitle,
//                cardBodyText: cardBodyText,
//                selectedFont: selectedFont,
//                selectedTitleFont: selectedTitleFont
//            )
//            
//            let renderer = ImageRenderer(content: cardToRender)
//            
//            // 輸出解析度乘數：3.0 代表輸出實體像素 900x900，完美防禦視網膜螢幕鋸齒
//            renderer.scale = 3.0
//            
//            // 直接安全提取圖片
//            if let cgImage = renderer.cgImage {
//                return Image(uiImage: UIImage(cgImage: cgImage))
//            }
//            
//            // 萬一失敗的降級安全兜底（回傳空白圖片，避免 App 崩潰）
//            return Image(uiImage: UIImage())
//        }
//}
//
//
//#Preview {
//    FontWallpaperShareView()
//}
//
//
//// 1. 專門給 ImageRenderer 離屏渲染用的【純靜態】檢視，徹底擺脫 TextField 與 Binding 限制
//struct WallpaperSnapshotCard: View {
//    let cardTitle: String
//    let cardBodyText: String
//    let selectedFont: CustomFontOption
//    let selectedTitleFont: CustomFontOption
//    
//    var body: some View {
//        ZStack {
//            Color.brown // 保持跟編輯畫面一模一樣的背景色
//            
//            VStack(spacing: 0) {
//                // 標題區
//                ZStack(alignment: .top) {
//                    if cardTitle.isEmpty {
//                        Text("Enter your blessing\nmessage")
//                            .font(.custom("FlaemischeKanzleischrift", size: 38))
//                    } else {
//                        Text(cardTitle)
//                            .font(selectedTitleFont.targetFont(28))
//                    }
//                }
//                .multilineTextAlignment(.center)
//                .foregroundStyle(Color.white)
//                .padding(.horizontal)
//                .padding(.bottom, 48)
//                
//                // 內文區
//                ZStack(alignment: .topLeading) {
//                    if cardBodyText.isEmpty {
//                        Text("Dear [Name]\n\nSay something...")
//                            .foregroundStyle(Color.white.opacity(0.6))
//                            .padding()
//                    } else {
//                        Text(cardBodyText)
//                            .font(selectedFont.targetFont(18))
//                            .foregroundStyle(Color.white)
//                            .padding()
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .topLeading) // 模擬原有排版
//            }
//        }
//        // 這裡設定你期望輸出的物理圖片尺寸（例如：300x300，搭配 scale = 3.0 就會輸出 900x900 的高畫質圖）
//        .frame(width: 300, height: 300)
//    }
//}
//
//
//#Preview {
//    WallpaperSnapshotCard(cardTitle: "123", cardBodyText: "1456", selectedFont: FontManager.shared.defaultBodyFont, selectedTitleFont: FontManager.shared.defaultTitleFont)
//}
