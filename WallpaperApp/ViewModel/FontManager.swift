

//
//  FontManager.swift
//  WallpaperApp
//

import SwiftUI


struct CustomFontOption: Identifiable, Equatable {
    let id = UUID()
    let displayName: String
    let fontName: String
    let displayFont: Font
    let targetFont: (CGFloat) -> Font
    
    static func == (lhs: CustomFontOption, rhs: CustomFontOption) -> Bool {
        lhs.fontName == rhs.fontName
    }
}



/// 全域字型管理器（單例）
class FontManager {
    static let shared = FontManager()
    
    private init() {}
    
    /// 所有可用字型（全域共用）
    let fontOptions: [CustomFontOption] = [
        CustomFontOption(
            displayName: "標準",
            fontName: "System",
            displayFont: .system(.body, design: .default),
            targetFont: { .system(size: $0, weight: .regular, design: .default) }
        ),
        CustomFontOption(
            displayName: "calligraphy",
            fontName: "FlaemischeKanzleischrift",
            displayFont: .custom("FlaemischeKanzleischrift", size: 14),
            targetFont: { .custom("FlaemischeKanzleischrift", size: $0) }
        ),
        CustomFontOption(
            displayName: "bold handwriting",
            fontName: "Big-Snow",
            displayFont: .custom("Big-Snow", size: 14),
            targetFont: { .custom("Big-Snow", size: $0) }
        ),
        CustomFontOption(
            displayName: "辰宇落雁",
            fontName: "ChenYuluoyan-2.0-Thin",
            displayFont: .custom("ChenYuluoyan-2.0-Thin", size: 14),
            targetFont: { _ in .custom("ChenYuluoyan-2.0-Thin", size: 30) }
        ),
        CustomFontOption(
            displayName: "中文手寫粗體",
            fontName: "StarPandaKidsBeta2.1",
            displayFont: .custom("StarPandaKidsBeta2.1", size: 14),
            targetFont: { _ in .custom("StarPandaKidsBeta2.1", size: 30) }
        )
    ]
    
    
  
    
    /// 取得預設字型
    var defaultFont: CustomFontOption {
        fontOptions[0]
    }
}



