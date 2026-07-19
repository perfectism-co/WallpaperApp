//
//  FaceLightingView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/18.
//

import SwiftUI
import Vision

struct FaceLightingView: View {
    let originalImage = UIImage(named: "1-2") ?? UIImage()
    
    // UI 顯示用的相片
    @State private var currentDisplayImage: UIImage = UIImage()
    
    // 核心控制參數
    @State private var exposureCount: Int = 0 // 點擊次數記數器
    @State private var savedFaceRects: [CGRect] = [] // 記憶辨識到的人臉座標 (Core Image 座標系)
    @State private var isAnalyzing: Bool = true
    
    let dodgeManager = FaceDodgeManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // 頂端狀態列
            HStack {
                Text(isAnalyzing ? "正在初次分析人臉..." : "目前補光層數: \(exposureCount) 層")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            // 照片顯示區域
            Image(uiImage: currentDisplayImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .onAppear {
                    // 畫面一打開，先顯示原圖，並啟動一次性人臉辨識
                    currentDisplayImage = originalImage
                    runOneTimeFaceDetection()
                }
            
            // 按鈕控制區
            HStack(spacing: 30) {
                // 取消補光鍵 (每按一次就扣一層)
                Button(action: {
                    if exposureCount > 0 {
                        exposureCount -= 1
                        updateImageOutput()
                    }
                }) {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                        Text("取消補光")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(exposureCount == 0 ? Color.gray : Color.red)
                    .cornerRadius(10)
                }
                .disabled(exposureCount == 0 || isAnalyzing)
                
                // 按下按鈕就對人臉補一次光
                Button(action: {
                    exposureCount += 1
                    updateImageOutput()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("人臉補光")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(isAnalyzing ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isAnalyzing)
            }
            .padding(.bottom, 30)
        }
    }
    
    /// 核心流程 1：一次性分析人臉位置並記錄
    private func runOneTimeFaceDetection() {
        guard let ciImage = CIImage(image: originalImage) else { return }
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let results = request.results as? [VNFaceObservation], error == nil else {
                DispatchQueue.main.async { self.isAnalyzing = false }
                return
            }
            
            // 【關鍵點】：Core Image 的原點在左下角，Vision 的原點也在左下角。
            // 我們直接把 Vision 的 0~1 比例，放大成相片的實體像素尺寸，直接給 CIColorCube/Gradient 使用。
            let imageSize = CGSize(width: originalImage.size.width, height: originalImage.size.height)
            
            let ciCoordinatesRects = results.map { observation -> CGRect in
                let box = observation.boundingBox
                return CGRect(
                    x: box.origin.x * imageSize.width,
                    y: box.origin.y * imageSize.height,
                    width: box.width * imageSize.width,
                    height: box.height * imageSize.height
                )
            }
            
            DispatchQueue.main.async {
                self.savedFaceRects = ciCoordinatesRects
                self.isAnalyzing = false
            }
        }
        
        // 加上我們上一題寫的 Preview 防禦程式碼
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            request.usesCPUOnly = true
        }
        #endif
        
        let orientation = CGImagePropertyOrientation(originalImage.imageOrientation)
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    /// 核心流程 2：依據點擊次數即時渲染
    private func updateImageOutput() {
        if exposureCount == 0 {
            currentDisplayImage = originalImage
            return
        }
        
        // 在背景線程進行 Core Image 渲染，確保按按鈕時 UI 絲滑不卡頓
        DispatchQueue.global(qos: .userInteractive).async {
            if let renderedImage = self.dodgeManager.applyFaceDodge(
                to: self.originalImage,
                faceRects: self.savedFaceRects,
                count: self.exposureCount
            ) {
                DispatchQueue.main.async {
                    self.currentDisplayImage = renderedImage
                }
            }
        }
    }
}

#Preview {
    FaceLightingView()
}
