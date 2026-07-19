//
//  getDominantColor.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/24.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

func getMixDominantColor(from image: UIImage) -> Color {
    // 1. 將 UIImage 轉為 CIImage
    guard let ciImage = CIImage(image: image) else { return .black }
    
    // 2. 使用 CIAreaAverage 濾鏡
    let filter = CIFilter.areaAverage()
    filter.inputImage = ciImage
    filter.extent = ciImage.extent
    
    // 3. 輸出結果 (得到一個 1x1 像素的圖片)
    guard let output = filter.outputImage else { return .black }
    
    // 4. 讀取顏色數據
    var bitmap = [UInt8](repeating: 0, count: 4)
    let context = CIContext()
    context.render(output,
                   toBitmap: &bitmap,
                   rowBytes: 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBA8,
                   colorSpace: nil)
    
    // 5. 轉為 SwiftUI Color
    return Color(red: Double(bitmap[0]) / 255.0,
                 green: Double(bitmap[1]) / 255.0,
                 blue: Double(bitmap[2]) / 255.0)
}



import SwiftUI
import CoreGraphics

// 🎯 iOS 26+ 最新標準：使用 async/await 進行背景色彩分析
extension UIImage {
    
    /// 獲取圖片中面積最大（出現頻率最高）的顏色
    func getDominantColor() async -> Color {
        // 1. 現代縮圖 API：將圖片大幅縮小以提升效能 (例如 50x50 像素)
        let targetSize = CGSize(width: 50, height: 50)
        
        // preparingThumbnail(of:) 是極度節省記憶體的現代 API
        guard let thumbnail = self.preparingThumbnail(of: targetSize),
              let cgImage = thumbnail.cgImage else {
            return .black
        }
        
        // 2. 將任務推入背景執行緒，避免阻塞主畫面 (UI Thread)
        return await Task.detached {
            let width = cgImage.width
            let height = cgImage.height
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            
            var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            // 提取像素數據
            guard let context = CGContext(
                data: &rawData,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return .black }
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            // 3. 建立計數器 (Hash Map) 來統計顏色出現次數
            var colorFrequency: [UInt32: Int] = [:]
            var maxCount = 0
            var dominantHex: UInt32 = 0
            
            // 4. 遍歷所有像素
            for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
                let r = rawData[i]
                let g = rawData[i+1]
                let b = rawData[i+2]
                let a = rawData[i+3]
                
                // 忽略完全透明或接近透明的像素
                if a < 50 { continue }
                
                // 💡 核心魔法：色彩量化 (Color Quantization)
                // 除以 16 再乘以 16，抹除低位元的細微色差，讓相近的顏色歸為同一個 Bucket
                let quantizedR = UInt32(r / 16 * 16)
                let quantizedG = UInt32(g / 16 * 16)
                let quantizedB = UInt32(b / 16 * 16)
                
                // 將 RGB 壓縮成一個 UInt32 作為 Dictionary 的 Key 加速比對
                let hex = (quantizedR << 16) | (quantizedG << 8) | quantizedB
                
                colorFrequency[hex, default: 0] += 1
                
                // 記錄目前最高的票數
                if let count = colorFrequency[hex], count > maxCount {
                    maxCount = count
                    dominantHex = hex
                }
            }
            
            // 5. 將最高票的 Hex 轉回 SwiftUI Color
            let finalR = Double((dominantHex >> 16) & 0xFF) / 255.0
            let finalG = Double((dominantHex >> 8) & 0xFF) / 255.0
            let finalB = Double(dominantHex & 0xFF) / 255.0
            
            return Color(red: finalR, green: finalG, blue: finalB)
        }.value
    }
}
