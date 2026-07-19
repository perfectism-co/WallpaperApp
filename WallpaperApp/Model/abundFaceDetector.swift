//
//  FaceDetector.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/18.
//

import UIKit
import Vision
import ImageIO

class FaceDetector {
    
    /// 偵測圖片中是否有人臉
    /// - Parameters:
    ///   - image: 來源圖片
    ///   - completion: 偵測完成後的 CallBack，回傳 (是否有人臉, 人臉數量, 人臉在圖片中的絕對座標)
    func detectFaces(in image: UIImage, completion: @escaping (Bool, Int, [CGRect]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(false, 0, [])
            return
        }
        
        // 1. 建立人臉偵測請求
        let request = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                print("Vision 偵測失敗: \(error.localizedDescription)")
                completion(false, 0, [])
                return
            }
            
            // 2. 取得偵測結果，轉型為 VNFaceObservation
            guard let results = request.results as? [VNFaceObservation] else {
                completion(false, 0, [])
                return
            }
            
            let hasFace = !results.isEmpty
            let faceCount = results.count
            
            // 3. 解析每張臉的座標
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            let faceRects = results.map { observation -> CGRect in
                // Vision 回傳的是 0.0 ~ 1.0 的正規化座標，且原點在左下角
                return self.convertNormalizedRect(observation.boundingBox, to: imageSize)
            }
            
            completion(hasFace, faceCount, faceRects)
        }
        
        // 3. 設定圖片方向（若方向錯誤，會嚴重影響辨識率）
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        
        // 4. 在背景線程執行偵測，避免阻塞主執行緒
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("無法執行 Vision 請求: \(error)")
                completion(false, 0, [])
            }
        }
    }
    
    /// 將 Vision 的正規化座標轉換為實體像素座標
    private func convertNormalizedRect(_ normalizedRect: CGRect, to size: CGSize) -> CGRect {
        // Vision 原點在左下角，Core Image 原點也在左下角
        let w = normalizedRect.width * size.width
        let h = normalizedRect.height * size.height
        let x = normalizedRect.origin.x * size.width
        let y = normalizedRect.origin.y * size.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

// 轉換 UIImage 方向至 CGImagePropertyOrientation 的輔助擴充
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
