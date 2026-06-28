//
//  ColorThemeManager.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/24.
//

import SwiftUI

struct ColorThemeManager {
    
    /// 檢查並校正取出的主要顏色
    /// - Parameter originalColor: 從圖片取出的原始顏色
    /// - Returns: 經過濾與校正後的顏色
    static func adjustDominantColor(_ originalColor: Color) -> Color {
        // 將 SwiftUI Color 轉為 UIColor 以便精準提取 HSB 數值
        let uiColor = UIColor(originalColor)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // 嘗試取得 HSB 數值，若失敗則回傳原色
        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return originalColor
        }
        
        // ------------------------------------------------
        // 🎨 規則 1：判斷是否為「咖啡色系」(Brown)
        // ------------------------------------------------
        // 色相 (Hue)：約在 0.0 ~ 0.15 之間 (紅色、橘色區間)
        // 飽和度 (Saturation)：大於 0.3 (排除掉太灰的顏色)
        // 亮度 (Brightness)：大約在 0.15 ~ 0.6 之間 (太亮會變橘色，太暗會變黑色)
        let isBrownish = (hue >= 0.0 && hue <= 0.15) &&
                         (saturation >= 0.3) &&
                         (brightness >= 0.15 && brightness <= 0.6)
        
        if isBrownish {
            // 💡 在這裡換成你想要指定的顏色 (例如統一換成深藍灰色)
            //return Color(red: 0.2, green: 0.3, blue: 0.4)
            return Color(hue: 0.1552, saturation: 1.0, brightness: 0.8)
        }
        
        // ------------------------------------------------
        // 🎨 預留規則 2：未來的其他判斷 (範例)
        // ------------------------------------------------
        /*
        let isTooBright = brightness > 0.9
        if isTooBright {
            return Color.gray // 如果太刺眼，強制給灰色
        }
        */
        
        // 若都沒有命中任何規則，就乖乖回傳原本的照片主要顏色
        return originalColor
    }
}
