//
//  getDominantColor.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/24.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

func getDominantColor(from image: UIImage) -> Color {
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
