//import UIKit
//import CoreImage
//
//class LUTFilterManager {
//    
//    /// 將 2D 長條 LUT 圖片轉換為 CIColorCube 預期的 3D 顏色查找表（解決綠色通道二次反轉問題）
//    /// - Parameter lutImageName: 放在 Bundle 中的 LUT 圖片名稱（不需加 .png）
//    func makeColorCubeFilter(lutImageName: String) -> CIFilter? {
//        // 1. 讀取 Bundle 中的檔案
//        guard let filePath = Bundle.main.path(forResource: lutImageName, ofType: "png"),
//              let uiImage = UIImage(contentsOfFile: filePath),
//              let cgImage = uiImage.cgImage else {
//            print("❌ 無法在 Bundle 中找到或載入名為 \(lutImageName).png 的圖片")
//            return nil
//        }
//        
//        let width = cgImage.width
//        let height = cgImage.height
//        let dimension = height
//        
//        // 2. 使用標準的 sRGB 色彩空間，防止 DeviceRGB 造成的色彩與伽馬（Gamma）值偏移
//        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
//            print("❌ 無法建立 sRGB 色彩空間")
//            return nil
//        }
//        
//        let totalPixels = width * height
//        var rawData = [UInt8](repeating: 0, count: totalPixels * 4)
//        
//        // 3. 建立最純粹的 CGContext
//        // 記憶體排列順序：y = 0 代表圖片的最底部（Green = 0）
//        guard let context = CGContext(
//            data: &rawData,
//            width: width,
//            height: height,
//            bitsPerComponent: 8,
//            bytesPerRow: width * 4,
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
//        ) else {
//            print("❌ 無法建立 CGContext")
//            return nil
//        }
//        
//        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
//        
//        // 4. 建立 3D 顏色立方體陣列
//        let cubeSize = dimension * dimension * dimension * 4
//        var colorCubeData = [Float](repeating: 0.0, count: cubeSize)
//        
//        // 5. 進行精準的 2D 到 3D 空間映射
//        for y in 0..<height {
//            for x in 0..<width {
//                let pixelIndex = y * width + x
//                let offset = pixelIndex * 4
//                
//                let r = Float(rawData[offset]) / 255.0
//                let g = Float(rawData[offset + 1]) / 255.0
//                let b = Float(rawData[offset + 2]) / 255.0
//                let a = Float(rawData[offset + 3]) / 255.0
//                
//                // 坐標映射邏輯：
//                // - 紅色（R）在單一色塊內水平變化
//                let rIndex = x % dimension
//                // - 藍色（B）代表第幾張色塊切片
//                let bIndex = x / dimension
//                // - 綠色（G）在垂直方向變化。
//                // 由於 CGContext 記憶體首行（y = 0）已對應圖片底部（G = 0.0），
//                // 故 gIndex 直接等於 y，不需任何手動反轉。
//                let gIndex = y
//                
//                // CIColorCube 規格公式：Index = (B * N^2 + G * N + R) * 4
//                let targetIndex = (bIndex * dimension * dimension + gIndex * dimension + rIndex) * 4
//                
//                // 防禦性檢查，避免陣列越界
//                if targetIndex >= 0 && targetIndex < cubeSize - 3 {
//                    colorCubeData[targetIndex] = r
//                    colorCubeData[targetIndex + 1] = g
//                    colorCubeData[targetIndex + 2] = b
//                    colorCubeData[targetIndex + 3] = a
//                }
//            }
//        }
//        
//        // 6. 建立 CIColorCube 濾鏡
//        let cubeData = Data(bytes: &colorCubeData, count: colorCubeData.count * MemoryLayout<Float>.size)
//        let filter = CIFilter(name: "CIColorCube")
//        filter?.setValue(dimension, forKey: "inputCubeDimension")
//        filter?.setValue(cubeData, forKey: "inputCubeData")
//        
//        return filter
//    }
//    
//    /// 執行濾鏡處理
//    func applyFilter(to userImage: UIImage, lutName: String) -> UIImage? {
//        guard let ciInput = CIImage(image: userImage),
//              let cubeFilter = makeColorCubeFilter(lutImageName: lutName) else {
//            return nil
//        }
//        
//        cubeFilter.setValue(ciInput, forKey: kCIInputImageKey)
//        
//        guard let ciOutput = cubeFilter.outputImage else {
//            print("❌ Core Image 無法產生 outputImage")
//            return nil
//        }
//        
//        let context = CIContext(options: nil)
//        guard let cgImage = context.createCGImage(ciOutput, from: ciOutput.extent) else {
//            print("❌ 無法建立 CGImage 輸出")
//            return nil
//        }
//        
//        return UIImage(cgImage: cgImage)
//    }
//}



import UIKit
import CoreImage

class LUTFilterManager {
    
    /// 將 2D 長條 LUT 圖片轉換為 3D 顏色查找表（維持原始映射，僅修復色彩空間加重問題）
    /// - Parameter lutImageName: 放在 Bundle 中的 LUT 圖片名稱（不需加 .png）
    func makeColorCubeFilter(lutImageName: String) -> CIFilter? {
        // 1. 讀取 Bundle 中的檔案
        guard let filePath = Bundle.main.path(forResource: lutImageName, ofType: "png"),
              let uiImage = UIImage(contentsOfFile: filePath),
              let cgImage = uiImage.cgImage else {
            print("❌ 無法在 Bundle 中找到或載入名為 \(lutImageName).png 的圖片")
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let dimension = height
        
        // 2. 使用標準的 sRGB 色彩空間，防止 DeviceRGB 造成的色彩與伽馬（Gamma）值偏移
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            print("❌ 無法建立 sRGB 色彩空間")
            return nil
        }
        
        let totalPixels = width * height
        var rawData = [UInt8](repeating: 0, count: totalPixels * 4)
        
        // 3. 建立最純粹的 CGContext
        // 記憶體排列順序：y = 0 代表圖片的最底部（Green = 0）
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("❌ 無法建立 CGContext")
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 4. 建立 3D 顏色立方體陣列
        let cubeSize = dimension * dimension * dimension * 4
        var colorCubeData = [Float](repeating: 0.0, count: cubeSize)
        
        // 5. 進行精準的 2D 到 3D 空間映射（完全維持你原本正確的邏輯）
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * width + x
                let offset = pixelIndex * 4
                
                let r = Float(rawData[offset]) / 255.0
                let g = Float(rawData[offset + 1]) / 255.0
                let b = Float(rawData[offset + 2]) / 255.0
                let a = Float(rawData[offset + 3]) / 255.0
                
                let rIndex = x % dimension
                let bIndex = x / dimension
                let gIndex = y
                
                let targetIndex = (bIndex * dimension * dimension + gIndex * dimension + rIndex) * 4
                
                if targetIndex >= 0 && targetIndex < cubeSize - 3 {
                    colorCubeData[targetIndex] = r
                    colorCubeData[targetIndex + 1] = g
                    colorCubeData[targetIndex + 2] = b
                    colorCubeData[targetIndex + 3] = a
                }
            }
        }
        
        // 6. 【唯一修改點】改用 CIColorCubeWithColorSpace 並指定 sRGB 色彩空間
        // 這樣可以阻止 Core Image 對輸出數據進行二次伽馬放大，還原 Photoshop 的真實發色
        let cubeData = Data(bytes: &colorCubeData, count: colorCubeData.count * MemoryLayout<Float>.size)
        
        guard let filter = CIFilter(name: "CIColorCubeWithColorSpace") else {
            print("❌ 無法建立 CIColorCubeWithColorSpace 濾鏡")
            return nil
        }
        filter.setValue(dimension, forKey: "inputCubeDimension")
        filter.setValue(cubeData, forKey: "inputCubeData")
        
        // 鎖定色彩空間為 sRGB
        if let sRGBSpace = CGColorSpace(name: CGColorSpace.sRGB) {
            filter.setValue(sRGBSpace, forKey: "inputColorSpace")
        }
        
        return filter
    }
    
    /// 執行濾鏡處理
//    func applyFilter(to userImage: UIImage, lutName: String) -> UIImage? {
//        guard let ciInput = CIImage(image: userImage),
//              let cubeFilter = makeColorCubeFilter(lutImageName: lutName) else {
//            return nil
//        }
//        
//        cubeFilter.setValue(ciInput, forKey: kCIInputImageKey)
//        
//        guard let ciOutput = cubeFilter.outputImage else {
//            print("❌ Core Image 無法產生 outputImage")
//            return nil
//        }
//        
//        let context = CIContext(options: nil)
//        guard let cgImage = context.createCGImage(ciOutput, from: ciOutput.extent) else {
//            print("❌ 無法建立 CGImage 輸出")
//            return nil
//        }
//        
//        return UIImage(cgImage: cgImage)
//    }
    
    func applyFilter(to userImage: UIImage, lutName: String) -> UIImage? {
        // 🎯 修正點 1：改用 userImage.cgImage 建立 CIImage，徹底避開實機低解析度 Proxy 陷阱
        guard let cgInputImage = userImage.cgImage else {
            print("❌ 無法獲取 userImage 的 cgImage")
            return nil
        }
        
        let ciInput = CIImage(cgImage: cgInputImage)
        
        guard let cubeFilter = makeColorCubeFilter(lutImageName: lutName) else {
            return nil
        }
        
        cubeFilter.setValue(ciInput, forKey: kCIInputImageKey)
        
        guard let ciOutput = cubeFilter.outputImage else {
            print("❌ Core Image 無法產生 outputImage")
            return nil
        }
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciOutput, from: ciOutput.extent) else {
            print("❌ 無法建立 CGImage 輸出")
            return nil
        }
        
        // 🎯 修正點 2：輸出時必須還原 userImage 原本的 scale 與 orientation，確保 Retina 螢幕清晰顯示
        return UIImage(cgImage: cgImage, scale: userImage.scale, orientation: userImage.imageOrientation)
    }
}
