//
//  FaceRostoProfolitTest.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/18.
//

import SwiftUI

struct FaceRostoProfolitTest: View {
    let originalImage = UIImage(named: "1-2") ?? UIImage()
        
        @State private var currentDisplayImage: UIImage = UIImage()
        @State private var exposureCount: Int = 0
        @State private var savedFaceRects: [CGRect] = []
        @State private var isAnalyzing: Bool = true
        
        // 引入共用的兩個工具類別
        let dodgeManager = FaceDodgeManager()
        let detectionManager = FaceDetectionManager()
        
        var body: some View {
            VStack(spacing: 20) {
                HStack {
                    Text(isAnalyzing ? "正在初次分析人臉..." : "目前補光層數: \(exposureCount) 層")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                
                Image(uiImage: currentDisplayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .onAppear {
                        currentDisplayImage = originalImage
                        
                        // 呼叫共用 Function (這裡不傳 viewSize，取得 Core Image 專用座標)
                        detectionManager.detectFaces(in: originalImage, viewSize: nil) { count, rects in
                            self.savedFaceRects = rects
                            self.isAnalyzing = false
                        }
                    }
                
                HStack(spacing: 30) {
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
        
        private func updateImageOutput() {
            if exposureCount == 0 {
                currentDisplayImage = originalImage
                return
            }
            
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
    FaceRostoProfolitTest()
}
