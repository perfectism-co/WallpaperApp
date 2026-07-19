//
//  FaceDetectionManager.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/18.
//



import UIKit
import Vision

class FaceDetectionManager {
    
    /// 偵測人臉並提取人臉數量與座標
    /// - Parameters:
    ///   - image: 輸入的 UIImage
    ///   - viewSize: 選擇性參數。若需要 SwiftUI UI 座標（左上原點），請傳入 View 的尺寸；若需要 Core Image 實體像素座標（左下原點），傳入 nil 即可。
    ///   - completion: 偵測完成後的 CallBack，回傳人臉總數與轉換後的 CGRect 陣列
//    func detectFaces(in image: UIImage, viewSize: CGSize? = nil, completion: @escaping (Int, [CGRect]) -> Void) {
//        guard let ciImage = CIImage(image: image) else {
//            completion(0, [])
//            return
//        }
//        
//        let request = VNDetectFaceRectanglesRequest { request, error in
//            if error != nil {
//                DispatchQueue.main.async { completion(0, []) }
//                return
//            }
//            
//            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
//                DispatchQueue.main.async { completion(0, []) }
//                return
//            }
//            
//            let convertedRects = results.map { observation -> CGRect in
//                let box = observation.boundingBox
//                
//                if let size = viewSize {
//                    // 1. 轉成 SwiftUI 畫面使用的 UI 座標（原點在左上）
//                    let x = box.origin.x * size.width
//                    let w = box.width * size.width
//                    let h = box.height * size.height
//                    let y = (1.0 - box.origin.y - box.height) * size.height
//                    return CGRect(x: x, y: y, width: w, height: h)
//                } else {
//                    // 2. 轉成 Core Image 濾鏡使用的實體像素座標（原點在左下）
//                    let imageSize = CGSize(width: image.size.width, height: image.size.height)
//                    return CGRect(
//                        x: box.origin.x * imageSize.width,
//                        y: box.origin.y * imageSize.height,
//                        width: box.width * imageSize.width,
//                        height: box.height * imageSize.height
//                    )
//                }
//            }
//            
//            DispatchQueue.main.async {
//                // 回傳總數值與對應座標
//                completion(results.count, convertedRects)
//            }
//        }
//        
//        #if DEBUG
//        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
//            request.usesCPUOnly = true
//        }
//        #endif
//        
////        // 🔥 關鍵修正 1：無論是不是 Preview，在實機上也強迫 Vision 使用 CPU 進行最高精度演算
////        request.usesCPUOnly = true
////        
////        // 🔥 關鍵修正 2：如果 iOS 版本夠新，強制指定使用準確度優先的改進演算法
////        if #available(iOS 17.0, *) {
////            request.revision = VNDetectFaceRectanglesRequestRevision3 // 使用最新、最精準的辨識模型版本
////        }
//        
//        
//        let orientation = CGImagePropertyOrientation(image.imageOrientation)
//        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation, options: [:])
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            try? handler.perform([request])
//        }
//    }
    
    func detectFaces(in image: UIImage, viewSize: CGSize? = nil, completion: @escaping (Int, [CGRect]) -> Void) {
        // 🎯 修正點：改用 image.cgImage 建立 CIImage
        guard let cgImage = image.cgImage else {
            completion(0, [])
            return
        }
        let ciImage = CIImage(cgImage: cgImage)
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            if error != nil {
                DispatchQueue.main.async { completion(0, []) }
                return
            }
            
            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                DispatchQueue.main.async { completion(0, []) }
                return
            }
            
            let convertedRects = results.map { observation -> CGRect in
                let box = observation.boundingBox
                
                if let size = viewSize {
                    let x = box.origin.x * size.width
                    let w = box.width * size.width
                    let h = box.height * size.height
                    let y = (1.0 - box.origin.y - box.height) * size.height
                    return CGRect(x: x, y: y, width: w, height: h)
                } else {
                    let imageSize = CGSize(width: image.size.width, height: image.size.height)
                    return CGRect(
                        x: box.origin.x * imageSize.width,
                        y: box.origin.y * imageSize.height,
                        width: box.width * imageSize.width,
                        height: box.height * imageSize.height
                    )
                }
            }
            
            DispatchQueue.main.async {
                completion(results.count, convertedRects)
            }
        }
        
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            request.usesCPUOnly = true
        }
        #endif
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
