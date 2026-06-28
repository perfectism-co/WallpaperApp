////
////  SwiftUIView.swift
////  WallpaperApp
////
////  Created by macmini on 2026/6/25.
////
//
//import SwiftUI
//
//// 1. 定義字型模型（支援自訂字型與系統字型）
//struct CustomFontOption: Identifiable, Equatable {
//    let id = UUID()
//    let displayName: String
//    let fontName: String // 如果是系統內建或專案載入的字型名稱
//    let displayFont: Font // 用於選擇器按鈕上呈現該字型特色
//    let targetFont: (CGFloat) -> Font // 根據輸入框大小動態生成的 Font
//    
//    
//    // 只比較有意義的欄位（通常 fontName 或 displayName 就夠了）
//    static func == (lhs: CustomFontOption, rhs: CustomFontOption) -> Bool {
//        lhs.id == rhs.id ||
//        lhs.fontName == rhs.fontName
//    }
//}
//
//struct IGTextEditorView: View {
//    @State private var text: String = "輸入你的限時動態..."
//    @FocusState private var isInputFocused: Bool
//    
//    // 2. 準備字型清單 (請確保你的專案 Info.plist 已正確載入對應的 ttf/otf 檔案)
//    let fontOptions: [CustomFontOption] = [
//        CustomFontOption(displayName: "標準", fontName: "System", displayFont: .system(.body, design: .default), targetFont: { .system(size: $0, weight: .bold, design: .default) }),
//        CustomFontOption(displayName: "calligraphy", fontName: "FlaemischeKanzleischrift", displayFont: .custom("FlaemischeKanzleischrift", size: 14), targetFont: { .custom("FlaemischeKanzleischrift", size: $0) }),
//        CustomFontOption(displayName: "bold handwriting", fontName: "Big-Snow", displayFont: .custom("Big-Snow", size: 14), targetFont: { .custom("Big-Snow", size: $0) }),
//        CustomFontOption(displayName: "辰宇落雁", fontName: "ChenYuluoyan-2.0-Thin", displayFont: .custom("ChenYuluoyan-2.0-Thin", size: 14), targetFont: { .custom("ChenYuluoyan-2.0-Thin", size: $0) }),
//        CustomFontOption(displayName: "中文手寫粗體", fontName: "StarPandaKidsBeta2.1", displayFont: .custom("StarPandaKidsBeta2.1", size: 14), targetFont: { .custom("StarPandaKidsBeta2.1", size: $0) })
//    ]
//    
//    @State private var selectedFont: CustomFontOption
//    
//    init() {
//        // 預設為第一個字型
//        let defaultFont = CustomFontOption(displayName: "標準", fontName: "System", displayFont: .system(.body, design: .default), targetFont: { .system(size: $0, weight: .bold, design: .default) })
//        _selectedFont = State(initialValue: defaultFont)
//    }
//    
//    var body: some View {
//        ZStack {
//            // 背景（通常是照片或漸層，此處以深色背景示範）
//            Color.black.ignoresSafeArea()
//            
//            // 3. 文字編輯主體
//            TextField("", text: $text, axis: .vertical)
//                .font(selectedFont.targetFont(36)) // 動態套用使用者選中的大字型
//                .foregroundColor(.white)
//                .multilineTextAlignment(.center)
//                .padding()
//                .focused($isInputFocused)
//                .frame(maxWidth: .infinity, alignment: .center)
//        }
//        // 4. 利用 iOS 26 最標準的鍵盤附加視圖（附著在鍵盤正上方）
//        .safeAreaInset(edge: .bottom) {
//            if isInputFocused {
//                fontPickerToolbar
//                    .transition(.move(edge: .bottom).combined(with: .opacity))
//            }
//        }
//        .onAppear {
//            isInputFocused = true // 進入頁面自動彈起鍵盤
//        }
//        .onTapGesture {
//            isInputFocused = false // 點擊空白處，解除焦點，收起鍵盤
//        }
//    }
//    
//    // 5. 橫向滾動字型選擇器
//    private var fontPickerToolbar: some View {
//        VStack(spacing: 0) {
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 12) {
//                    ForEach(fontOptions) { option in
//                        Button {
//                            selectedFont = option
//                        } label: {
//                            Text(option.displayName)
//                                .font(option.displayFont)
//                                .foregroundColor(selectedFont == option ? .black : .white)
//                                .padding(.horizontal, 16)
//                                .padding(.vertical, 8)
//                                .background(
//                                    selectedFont == option ? Color.white : Color.white.opacity(0.15)
//                                )
//                                .clipShape(Capsule())
//                        }
//                        // 切換字型時給予 iOS 輕微的觸覺震動回饋
//                        .sensoryFeedback(.selection, trigger: selectedFont)
//                    }
//                }
//                .padding(.horizontal, 16)
//                .padding(.vertical, 10)
//            }
//            // 6. 套用 iOS 26 的「液態玻璃」材質做為工具列背景，極具現代感
//            .glassEffect()
//        }
//    }
//}
//
//


//import SwiftUI
//
//
//struct IGTextEditorView: View {
//    @State private var text: String = "輸入你的限時動態..."
//    @FocusState private var isInputFocused: Bool     // 保持不變
//    
//    @State private var selectedFont: CustomFontOption = FontManager.shared.defaultFont
//    
//    var body: some View {
//        ZStack {
//            Color.black.ignoresSafeArea()
//            
//            TextField("", text: $text, axis: .vertical)
//                .font(selectedFont.targetFont(36))
//                .foregroundColor(.white)
//                .multilineTextAlignment(.center)
//                .padding()
//                .focused($isInputFocused)
//                .frame(maxWidth: .infinity, alignment: .center)
//        }
//        .fontPickerToolbar(
//            selectedFont: $selectedFont,
//            isFocused: $isInputFocused      // 現在可以直接傳入
//        )
//        .onAppear {
//            isInputFocused = true
//        }
//        .onTapGesture {
//            isInputFocused = false
//        }
//    }
//}
//
//
//#Preview {
//    IGTextEditorView()
//}



import SwiftUI

// 1. 維持獨立的 View，確保自訂字型在離屏渲染時資料鎖死
struct WallpaperRenderCard: View {
    let text: String
    let fontName: String
    
    var body: some View {
        ZStack {
            Color.pink // 你的背景色
            
            Text(text)
                // 這裡填寫你確認過在 Info.plist 註冊過的 PostScript 名稱
                .font(.custom(fontName, size: 40))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
        }
        // 這裡給定明確的物理渲染尺寸（標準 iPhone 輸出解析度）
        .frame(width: 300, height: 600)
    }
}

struct FontWallpaperShareView: View {
    @State private var userText: String = "my test"
    @State private var selectedFontName: String = "Big-Snow"
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 畫面上顯示給用戶看的即時編輯視圖（縮放比例顯示）
            WallpaperRenderCard(text: userText, fontName: selectedFontName)
                .aspectRatio(300/600, contentMode: .fit)
                .frame(height: 400)
                .cornerRadius(12)
            
            // 2. 有理有據的【純圖片】分享：直接把 Image 丟給 item
            if let pureImage = renderCardToImage() {
                ShareLink(
                    item: pureImage,
                    preview: SharePreview("自製桌布", image: pureImage)
                ) {
                    Label("一鍵分享圖片", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            } else {
                Text("圖片產生中...")
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    // 3. 核心變更：不建立實體檔案，直接在記憶體中回傳 Image 類型
    @MainActor
    private func renderCardToImage() -> Image? {
        let cardToRender = WallpaperRenderCard(text: userText, fontName: selectedFontName)
        let renderer = ImageRenderer(content: cardToRender)
        
        // 解析度設定
        renderer.scale = 3.0
        
        // 先取得 CoreGraphics 圖片，再轉為系統支援點陣圖
        guard let cgImage = renderer.cgImage else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        
        // 關鍵：將 UIImage 轉換為 SwiftUI 專用的 Image 型別
        return Image(uiImage: uiImage)
    }
}


#Preview {
    FontWallpaperShareView()
}
