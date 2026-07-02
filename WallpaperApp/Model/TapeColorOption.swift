//
//  TapeColorOption.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/2.
//

import SwiftUI

// 定義紙膠帶顏色的資料模型
struct TapeColorOption: Hashable {
    let name: String // 顏色名稱
    let hex: String  // 十六進位色碼 (例如: "#FF3B30")
    
    // 計算屬性：將色碼字串轉換為 SwiftUI 的 Color 物件
    var color: Color {
        Color(hex: hex)
    }
}

// 擴充 Color 支援 Hex 初始化
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255) // 格式錯誤時預設為白色
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
