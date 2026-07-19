import SwiftUI
import Vision

struct FaceDetectionView: View {
    // 確保這裡的名稱與你 Assets 裡的圖片完全一致（例如 "avatar_test"）
    let testImage = UIImage(named: "6") ?? UIImage()
    
    @State private var detectedFaceRects: [CGRect] = []
    @State private var faceCountDescription: String = "等待相片載入..."
    
    var body: some View {
        VStack(spacing: 20) {
            Text(faceCountDescription)
                .font(.headline)
                .padding(.top)
            
            ZStack(alignment: .topLeading) {
                // 顯示原始照片
                Image(uiImage: testImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        // 使用 GeometryReader 取得圖片在畫面上「真正渲染出來」的尺寸
                        GeometryReader { imageGeometry in
                            Color.clear
                                .onAppear {
                                    // 圖片尺寸確定後，立刻執行偵測
                                    detectAndCalculateFaces(image: testImage, viewSize: imageGeometry.size)
                                }
                            
                            // 繪製紅框
                            ForEach(0..<detectedFaceRects.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 4)
                                    .path(in: detectedFaceRects[index])
                                    .stroke(Color.red, lineWidth: 3)
                            }
                        }
                    )
            }
            .padding()
            
            Spacer()
        }
    }
    
    /// 核心邏輯：單次偵測 + 即時轉換 UI 座標
    private func detectAndCalculateFaces(image: UIImage, viewSize: CGSize) {
        // 1. 改為直接使用 CIImage，避免轉 cgImage 時的解碼失敗問題
        guard let ciImage = CIImage(image: image) else {
            self.faceCountDescription = "錯誤：無法讀取圖片像素"
            return
        }
        
        self.faceCountDescription = "正在分析照片..."
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.faceCountDescription = "偵測失敗: \(error.localizedDescription)"
                }
                return
            }
            
            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                DispatchQueue.main.async {
                    self.faceCountDescription = "照片中完全找不到人臉"
                    self.detectedFaceRects = []
                }
                return
            }
            
            let convertedRects = results.map { observation -> CGRect in
                let box = observation.boundingBox
                
                // 座標轉換（Vision 左下原點 -> SwiftUI 左上原點）
                let x = box.origin.x * viewSize.width
                let w = box.width * viewSize.width
                let h = box.height * viewSize.height
                let y = (1.0 - box.origin.y - box.height) * viewSize.height
                
                return CGRect(x: x, y: y, width: w, height: h)
            }
            
            DispatchQueue.main.async {
                self.faceCountDescription = "偵測成功！共找到 \(results.count) 張人臉"
                self.detectedFaceRects = convertedRects
            }
        }
        
        
        #if DEBUG
        // 如果在偵錯模式下，且發現是在 Preview 中執行
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            request.usesCPUOnly = true
        }
        #endif
        
        // 2. 使用 ciImage 初始化 RequestHandler，並直接帶入正確的方向參數
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    // 列印出真正的錯誤原因到 Xcode Console 中，方便精準排查
                    self.faceCountDescription = "執行 Vision 失敗: \(error.localizedDescription)"
                    print("Vision 實際錯誤: \(error)")
                }
            }
        }
    }
}

#Preview {
    FaceDetectionView()
}
