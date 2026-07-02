

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
/// 全域字型管理器（單例）
class FontManager {
    static let shared = FontManager()
    
    private init() {}
    
    /// 內文字型選項
    let bodyFontOptions: [CustomFontOption] = [
        CustomFontOption(
            displayName: "標準",
            fontName: "System",
            displayFont: .system(.body, design: .default),
            targetFont: { _ in .system(.body, design: .default) }
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
    
    /// 標題字型選項
    let titleFontOptions: [CustomFontOption] = [
        CustomFontOption(
            displayName: "標準",
            fontName: "System",
            displayFont: .system(.body, design: .default),
            targetFont: { _ in .system(size: 30, weight: .black, design: .default) }
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
            targetFont: { _ in .custom("ChenYuluoyan-2.0-Thin", size: 50) }
        ),
        CustomFontOption(
            displayName: "中文手寫粗體",
            fontName: "StarPandaKidsBeta2.1",
            displayFont: .custom("StarPandaKidsBeta2.1", size: 14),
            targetFont: { _ in .custom("StarPandaKidsBeta2.1", size: 50) }
        )
    ]
    
    /// 取得預設字型
    var defaultBodyFont: CustomFontOption {
        bodyFontOptions[0]
    }
    
    var defaultTitleFont: CustomFontOption {
        titleFontOptions[1]
    }
}
