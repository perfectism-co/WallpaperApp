//
//  checkIsDominantColorDarkBrown.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/18.
//

//import UIKit
//import SwiftUI // 🔥 記得引入 SwiftUI，因為要使用 Color 型別
//
//extension UIImage {
//    /// 非同步檢查這張圖片的主色是否為深咖啡色
//    func checkIsDominantColorDarkBrown() async -> Bool {
//        // 1. 呼叫你寫在其他檔案的 func（此時它回傳的是 SwiftUI 的 Color）
//        let dominantColor = await self.getDominantColor()
//        
//        // 2. 核心修正：將 SwiftUI 的 Color 轉為 UIKit 的 UIColor
//        let uiColor = UIColor(dominantColor)
//        
//        // 3. 準備提取 HSB 數值
//        var hue: CGFloat = 0
//        var saturation: CGFloat = 0
//        var brightness: CGFloat = 0
//        var alpha: CGFloat = 0
//        
//        // 4. 改用轉換後的 uiColor 來呼叫 getHue
//        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
//            let isBrownish = (hue >= 0.0 && hue <= 0.2) &&
//                             (saturation >= 0.3) &&
//                             (brightness >= 0.15 && brightness <= 0.6)
//            return isBrownish
//        }
//        
//        return false
//    }
//}
//
//
//extension UIImage {
//    /// 僅負責提取主色的 HSB 數值
//    func getDominantColorHSB() async -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat)? {
//        let dominantColor = await self.getDominantColor()
//        let uiColor = UIColor(dominantColor)
//        
//        var h: CGFloat = 0
//        var s: CGFloat = 0
//        var b: CGFloat = 0
//        var a: CGFloat = 0
//        
//        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
//            return (h, s, b)
//        }
//        return nil
//    }
//}


import UIKit
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
    
    // MARK: - 1. 平均色計算函數 (維持你寫的邏輯，優化為配合 async 執行的輔助 func)
    private func calculateMixDominantColor() -> Color {
        // 將 UIImage 轉為 CIImage
        guard let ciImage = CIImage(image: self) else { return .black }
        
        // 使用 CIAreaAverage 濾鏡
        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage
        filter.extent = ciImage.extent
        
        // 輸出結果 (得到一個 1x1 像素的圖片)
        guard let output = filter.outputImage else { return .black }
        
        // 讀取顏色數據
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(output,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)
        
        // 轉為 SwiftUI Color
        return Color(red: Double(bitmap[0]) / 255.0,
                     green: Double(bitmap[1]) / 255.0,
                     blue: Double(bitmap[2]) / 255.0)
    }

    // MARK: - 2. 提取主色 HSB 數值 (配合 B 方案，改用平均色算法)
    func getDominantColorHSB() async -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat)? {
        // 🎯 核心修正：改用 Task.detached 在背景執行平均色濾鏡計算，不卡住 UI
        let dominantColor = await Task.detached(priority: .userInitiated) {
            return self.calculateMixDominantColor()
        }.value
        
        let uiColor = UIColor(dominantColor)
        
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return (h, s, b)
        }
        return nil
    }

    // MARK: - 3. 檢查主色是否為深咖啡色 (串接新版區間判定)
    func checkIsDominantColorDarkBrown() async -> Bool {
        // 🎯 核心修正：改呼叫上面新寫的 getDominantColorHSB()
        guard let hsb = await self.getDominantColorHSB() else { return false }
        
        // 💡 採用前幾題討論過、修正斷層與黑白誤判後的精細條件
        let hasEnoughColor = hsb.saturation >= 0.35
        
        let isBrownish = hasEnoughColor && (
            (hsb.hue >= 0.0 && hsb.hue <= 0.15 && hsb.brightness <= 0.3)
        )
        
        return isBrownish
    }
}
