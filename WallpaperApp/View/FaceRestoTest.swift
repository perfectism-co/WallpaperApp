//
//  FaceTest.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/18.
//

import SwiftUI

struct FaceRestoTest: View {
    let testImage = UIImage(named: "6") ?? UIImage()
        
        // 改為儲存人臉的數量值
        @State private var faceCount: Int = 0
        @State private var faceCountDescription: String = "等待相片載入..."
        
        // 引入共用管理員
        let detectionManager = FaceDetectionManager()
        
        var body: some View {
            VStack(spacing: 20) {
                Text(faceCountDescription)
                    .font(.headline)
                    .padding(.top)
                
                // 這裡可以根據提取到的人臉數量進行其他 UI 邏輯判斷
                if faceCount > 0 {
                    Text("成功提取到人臉數量：\(faceCount)")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
                
                ZStack(alignment: .topLeading) {
                    Image(uiImage: testImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onAppear {
                            self.faceCountDescription = "正在分析照片..."
                            // 既然不畫框了，直接傳 nil，就不需要 GeometryReader 了！
                            detectionManager.detectFaces(in: testImage, viewSize: nil) { count, rects in
                                self.faceCount = count
                                self.faceCountDescription = count > 0 ? "偵測成功！共找到 \(count) 張人臉" : "照片中完全找不到人臉"
                            }
                        }
//                        .overlay(
//                            GeometryReader { imageGeometry in
//                                Color.clear
//                                    .onAppear {
//                                        self.faceCountDescription = "正在分析照片..."
//                                        
//                                        // 呼叫共用 Function
//                                        detectionManager.detectFaces(in: testImage, viewSize: imageGeometry.size) { count, rects in
//                                            self.faceCount = count
//                                            if count > 0 {
//                                                self.faceCountDescription = "偵測成功！共找到 \(count) 張人臉"
//                                            } else {
//                                                self.faceCountDescription = "照片中完全找不到人臉"
//                                            }
//                                        }
//                                    }
//                            }
//                        )
                }
                .padding()
                
                Spacer()
            }
        }
}

#Preview {
    FaceRestoTest()
}
