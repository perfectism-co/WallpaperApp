//
//  FaceDodgeManager.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/18.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class FaceDodgeManager {
    
    private let context = CIContext(options: nil)
    
    /// 對指定的人臉區域進行柔邊曝光加亮
    /// - Parameters:
    ///   - inputImage: 原始照片 (UIImage)
    ///   - faceRects: Vision 偵測到的人臉實體像素座標陣列 (Core Image 座標系)
    ///   - count: 補光次數 (按幾次就乘以幾倍曝光)
    ///   - evPerClick: 單次點擊增加的曝光值 (建議 0.3 ~ 0.5，等同於 PS 的曝光度 20%~30%)
//    func applyFaceDodge(to inputImage: UIImage, faceRects: [CGRect], count: Int, evPerClick: Float = 0.4) -> UIImage? {
//        guard let ciInput = CIImage(image: inputImage), count > 0 else {
//            return inputImage // 次數為 0 或負數，直接回傳原圖
//        }
//        
//        let totalEV = evPerClick * Float(count)
//        
//        // 1. 先產生一張全圖加曝光後的影像
//        let exposureFilter = CIFilter.exposureAdjust()
//        exposureFilter.inputImage = ciInput
//        exposureFilter.ev = totalEV
//        guard let exposedImage = exposureFilter.outputImage else { return nil }
//        
//        // 2. 建立一張初始為全黑的遮罩底圖
//        var finalMask: CIImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0)).cropped(to: ciInput.extent)
//        
//        // 3. 針對每一張偵測到的人臉，製作柔邊圓形並「加強」到遮罩上
//        for rect in faceRects {
//            let centerX = rect.midX
//            let centerY = rect.midY
//            let centerPoint = CGPoint(x: centerX, y: centerY)
//            
//            // 依據人臉大小，動態算好比例（拿人臉寬與高中較大者作為基準半徑）
//            let faceRadius = max(rect.width, rect.height) * 0.5
//            
//            // 設定柔邊：內圈從人臉中心 20% 開始衰減，外圈擴散到人臉大小的 2.5 倍處才完全消失
//            let r1 = faceRadius * 0.2
//            let r2 = faceRadius * 2.5
//            
//            let radialGradient = CIFilter.radialGradient()
//            radialGradient.center = centerPoint
//            radialGradient.radius0 = Float(r1)
//            radialGradient.radius1 = Float(r2)
//            radialGradient.color0 = CIColor(red: 1, green: 1, blue: 1, alpha: 1) // 中心全白 (100% 補光)
//            radialGradient.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 0) //邊緣透明 (0% 補光)
//            
//            if let gradientOutput = radialGradient.outputImage?.cropped(to: ciInput.extent) {
//                // 使用「相加 (Addition)」混合模式，把多個人臉的柔邊圓形疊加在同一張遮罩上
//                let additionFilter = CIFilter.additionCompositing()
//                additionFilter.inputImage = gradientOutput
//                additionFilter.backgroundImage = finalMask
//                if let combinedMask = additionFilter.outputImage {
//                    finalMask = combinedMask
//                }
//            }
//        }
//        
//        // 4. 進行 Mask 混合：
//        // 遮罩白色（人臉中心）採用 exposedImage（加曝光圖）
//        // 遮罩黑色（背景四周）採用 ciInput（原圖）
//        // 遮罩漸層（柔邊邊緣）自動完美線性融合
//        let blendFilter = CIFilter.blendWithMask()
//        blendFilter.inputImage = exposedImage
//        blendFilter.backgroundImage = ciInput
//        blendFilter.maskImage = finalMask
//        
//        guard let finalCIImage = blendFilter.outputImage else { return nil }
//        
//        // 5. 渲染輸出
//        guard let cgImage = context.createCGImage(finalCIImage, from: ciInput.extent) else { return nil }
//        return UIImage(cgImage: cgImage)
//    }
    
    func applyFaceDodge(to inputImage: UIImage, faceRects: [CGRect], count: Int, evPerClick: Float = 0.4) -> UIImage? {
        // 🎯 修正點 1：改用 inputImage.cgImage 建立 CIImage
        guard let cgInputImage = inputImage.cgImage, count > 0 else {
            return inputImage // 次數為 0 或負數，直接回傳原圖
        }
        
        let ciInput = CIImage(cgImage: cgInputImage)
        
        let totalEV = evPerClick * Float(count)
        
        // 1. 先產生一張全圖加曝光後的影像
        let exposureFilter = CIFilter.exposureAdjust()
        exposureFilter.inputImage = ciInput
        exposureFilter.ev = totalEV
        guard let exposedImage = exposureFilter.outputImage else { return nil }
        
        // 2. 建立一張初始為全黑的遮罩底圖
        var finalMask: CIImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0)).cropped(to: ciInput.extent)
        
        // 3. 針對每一張偵測到的人臉，製作柔邊圓形並「加強」到遮罩上
        for rect in faceRects {
            let centerX = rect.midX
            let centerY = rect.midY
            let centerPoint = CGPoint(x: centerX, y: centerY)
            
            let faceRadius = max(rect.width, rect.height) * 0.5
            let r1 = faceRadius * 0.2
            let r2 = faceRadius * 2.5
            
            let radialGradient = CIFilter.radialGradient()
            radialGradient.center = centerPoint
            radialGradient.radius0 = Float(r1)
            radialGradient.radius1 = Float(r2)
            radialGradient.color0 = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
            radialGradient.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 0)
            
            if let gradientOutput = radialGradient.outputImage?.cropped(to: ciInput.extent) {
                let additionFilter = CIFilter.additionCompositing()
                additionFilter.inputImage = gradientOutput
                additionFilter.backgroundImage = finalMask
                if let combinedMask = additionFilter.outputImage {
                    finalMask = combinedMask
                }
            }
        }
        
        // 4. 進行 Mask 混合
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = exposedImage
        blendFilter.backgroundImage = ciInput
        blendFilter.maskImage = finalMask
        
        guard let finalCIImage = blendFilter.outputImage else { return nil }
        
        // 5. 渲染輸出
        guard let cgImage = context.createCGImage(finalCIImage, from: ciInput.extent) else { return nil }
        
        // 🎯 修正點 2：輸出時還原高畫質縮放係數與轉向資訊
        return UIImage(cgImage: cgImage, scale: inputImage.scale, orientation: inputImage.imageOrientation)
    }
}
