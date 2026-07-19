////
////  FilterAutoTest.swift
////  WallpaperApp
////
////  Created by macmini on 2026/7/18.
////
//
//import SwiftUI
//import PhotosUI
//
//struct FilterAutoTest: View {
//    
//    // 1. 在你的 View 或是 ViewModel 裡加上一個用來記錄目前 Task 的變數
//    @State private var faceDetectionTask: Task<Void, Never>? = nil
//    
//    @State private var selectedItem: PhotosPickerItem?
//    
//    // 職責分離：
//    // originalImage: 儲存從相簿選出來的「絕對原圖」
//    // currentDisplayImage: 儲存「經過濾鏡或補光加工後」最終呈現給使用者看的圖
//    @State private var originalImage: UIImage?
//    @State private var currentDisplayImage: UIImage?
//    
//    let detectionManager = FaceDetectionManager()
//    let dodgeManager = FaceDodgeManager()
//    let filterManager = LUTFilterManager()
//    
//    
//    @State private var exposureCount: Int = 0
//    @State private var savedFaceRects: [CGRect] = []
//    @State private var isAnalyzing: Bool = false
//    @State private var isShowDodge: Bool = true // 測試用，預設開啟
//    @State private var statusDescription: String = "請選擇照片"
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 25) {
//                
//                Text("濾鏡自動效果測試")
//                    .font(.title2)
//                    .bold()
//                    .padding(.top)
//                // 在 body 的 VStack 裡面最上方加入這個臨時按鈕
//                Button("🔥 強制用專案內名為 6 的圖片測試") {
//                    if let image6 = UIImage(named: "6") {
//                        self.isShowDodge = false
//                        self.exposureCount = 0
//                        self.savedFaceRects = []
//                        self.originalImage = image6
//                        self.currentDisplayImage = image6
//                        self.statusDescription = "正在用專案內 6 號圖片測試..."
//                        
//                        // 跑你的管線
//                        self.processAutoPipeline(for: image6)
//                    }
//                    
//                    if let image6 = UIImage(named: "6") {
//                        print("===== 橘色按鈕（Assets）數據 =====")
//                        print("UIImage 寬高: \(image6.size.width) x \(image6.size.height)")
//                        print("CGImage 實體像素寬高: \(image6.cgImage?.width ?? 0) x \(image6.cgImage?.height ?? 0)")
//                        print("Scale 縮放率: \(image6.scale)")
//                        
//                        // 原本的執行程式碼...
//                        self.processAutoPipeline(for: image6)
//                    }
//                    
//                }
//                .padding()
//                .background(Color.orange)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//                Text(statusDescription)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                
//                // 1. 影像顯示區
//                if let imageToDisplay = currentDisplayImage {
//                    Image(uiImage: imageToDisplay)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 350)
//                } else {
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color.gray.opacity(0.1))
//                        .frame(height: 350)
//                        .overlay(
//                            VStack(spacing: 10) {
//                                Image(systemName: "photo.on.rectangle")
//                                    .font(.largeTitle)
//                                    .foregroundColor(.gray)
//                                Text("尚未選取照片")
//                                    .foregroundColor(.gray)
//                            }
//                        )
//                        .padding(.horizontal)
//                }
//                
//                // 2. 選擇照片按鈕
//                PhotosPicker(selection: $selectedItem, matching: .images) {
//                    HStack {
//                        Image(systemName: "photo.badge.plus")
//                        Text("選擇照片")
//                    }
//                    .font(.headline)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                    .padding(.horizontal)
//                }
//                .onChange(of: selectedItem) { _, newItem in
//                    Task {
//                        // 1. 安全解包
//                        guard let item = newItem else { return }
//                        
//                        // 2. 獲取最純粹的 Data
//                        guard let data = try? await item.loadTransferable(type: Data.self),
//                              let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
//                            await MainActor.run { self.statusDescription = "❌ 影像資料載入失敗" }
//                            return
//                        }
//                        
//                        // 3. 進行最大長邊 2000 的高畫質降採樣與旋轉固化
//                        let maxDimension = 2000
//                        let options: [CFString: Any] = [
//                            kCGImageSourceCreateThumbnailFromImageAlways: true,
//                            kCGImageSourceCreateThumbnailWithTransform: true,
//                            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
//                            kCGImageSourceShouldCacheImmediately: true
//                        ]
//                        
//                        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
//                            await MainActor.run { self.statusDescription = "❌ 影像正規化失敗" }
//                            return
//                        }
//                        
//                        // 🔥 終極核心修正：強制指定 scale 為 1.0！
//                        // 這能確保這張圖片的 size 屬性反映的是真實的像素點（與 Assets 載入行為完全一致），
//                        // 絕不允許 iOS 系統因為實機螢幕解析度而自動給它設定成 2.0 或 3.0。
//                        let finalImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
//                        
//                        await MainActor.run {
//                            self.isShowDodge = false
//                            self.exposureCount = 0
//                            self.savedFaceRects = []
//                            self.originalImage = finalImage
//                            self.currentDisplayImage = finalImage
//                            self.statusDescription = "成功還原純淨尺寸，正在分析人臉..."
//                            
//                            // 執行自動化管線
//                            self.processAutoPipeline(for: finalImage)
//                            
//                            
//                            print("===== 相簿選取（PhotosPicker）數據 =====")
//                            print("UIImage 寬高: \(finalImage.size.width) x \(finalImage.size.height)")
//                            print("CGImage 實體像素寬高: \(finalImage.cgImage?.width ?? 0) x \(finalImage.cgImage?.height ?? 0)")
//                            print("Scale 縮放率: \(finalImage.scale)")
//                            
//                            // 原本的執行程式碼...
//                            self.processAutoPipeline(for: finalImage)
//                            
//                        }
//                        
//                        
//                    }
//                }
//                
//                // 修正點：改為符合 iOS 17+ 規範的 2 個參數寫法 (oldValue, newValue)
////                .onChange(of: selectedItem) { _, newItem in
////                    Task {
////                        // 1. 取得最原始、未經轉碼壓縮的原始 Data
////                        guard let data = try? await newItem?.loadTransferable(type: Data.self),
////                              let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
////                            await MainActor.run { self.statusDescription = "❌ 影像資料載入失敗" }
////                            return
////                        }
////                        
////                        // 2. 設定解碼參數：強制使用最高畫質、允許浮點數解碼
////                        let options: [CFString: Any] = [
////                            kCGImageSourceShouldCache: true,
////                            kCGImageSourceShouldAllowFloat: true
////                        ]
////                        
////                        // 3. 從 Source 中完整提取原始 CGImage 與轉向 (保留最純淨像素)
////                        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary) else { return }
////                        
////                        // 抓取原圖 Exif 轉向資訊
////                        var orientation: UIImage.Orientation = .up
////                        if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
////                           let exifOrientation = properties[kCGImagePropertyOrientation] as? UInt32 {
////                            
////                            // 轉換為正確的 UIImage 轉向型別
////                            switch exifOrientation {
////                            case 1: orientation = .up
////                            case 3: orientation = .down
////                            case 6: orientation = .right
////                            case 8: orientation = .left
////                            case 2: orientation = .upMirrored
////                            case 4: orientation = .downMirrored
////                            case 5: orientation = .leftMirrored
////                            case 7: orientation = .rightMirrored
////                            default: orientation = .up
////                            }
////                        }
////                        
////                        let finalImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
////                        
////                        // 4. 回到主線程更新狀態與管線
////                        await MainActor.run {
////                            self.isShowDodge = false
////                            self.exposureCount = 0
////                            self.savedFaceRects = []
////                            self.originalImage = finalImage
////                            self.currentDisplayImage = finalImage
////                            self.statusDescription = "成功載入原畫照片，正在分析人臉..."
////                            
////                            // 執行自動化管線
////                            self.processAutoPipeline(for: finalImage)
////                        }
////                    }
////                }
//                
//                // 3. 補光按鈕控制區
//                if isShowDodge && currentDisplayImage != nil {
//                    HStack(spacing: 30) {
//                        Button(action: {
//                            if exposureCount > 0 {
//                                exposureCount -= 1
//                                updateImageOutput()
//                            }
//                        }) {
//                            HStack {
//                                Image(systemName: "minus.circle.fill")
//                                Text("取消補光")
//                            }
//                            .font(.subheadline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(exposureCount == 0 ? Color.gray : Color.red)
//                            .cornerRadius(10)
//                        }
//                        .disabled(exposureCount == 0 || isAnalyzing)
//                        
//                        Button(action: {
//                            exposureCount += 1
//                            updateImageOutput()
//                        }) {
//                            HStack {
//                                Image(systemName: "plus.circle.fill")
//                                Text("人臉補光")
//                            }
//                            .font(.subheadline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(isAnalyzing ? Color.gray : Color.blue)
//                            .cornerRadius(10)
//                        }
//                        .disabled(isAnalyzing)
//                    }
//                    .padding(.bottom, 30)
//                }
//            }
//        }
//    }
//    
//    /// 核心自動化管線：先偵測人臉 -> 決定濾鏡 -> 更新基礎顯示圖
////    private func processAutoPipeline(for image: UIImage) {
////        self.isAnalyzing = true
////        
////        detectionManager.detectFaces(in: image, viewSize: nil) { count, rects in
////            
////            self.savedFaceRects = rects
////            self.isAnalyzing = false
////            
////            var finalProcessedImage = image
////            let lutName = count > 4 ? "resto_people_filter_lut" : "food_filter_lut"
////            if count < 5 {
////                self.isShowDodge = true
////            }
////            print("👉 偵測到 \(count) 張人臉，選擇濾鏡：\(lutName)")
////            
////            if let result = filterManager.applyFilter(to: image, lutName: lutName) {
////                finalProcessedImage = result
////                self.statusDescription = "🎉 自動套用濾鏡成功 (\(lutName))"
////            } else {
////                self.statusDescription = "❌ 濾鏡套用失敗，請檢查 Bundle 資源"
////            }
////            
////            // 關鍵點：把處理完的成果當作後續補光的「基底圖」
////            self.originalImage = finalProcessedImage
////            self.currentDisplayImage = finalProcessedImage
////        }
////    }
//    
//    // 輔助函數：用來統一更新狀態
//    private func executePipeline(with image: UIImage) {
//        self.isShowDodge = false
//        self.exposureCount = 0
//        self.savedFaceRects = []
//        self.originalImage = image
//        self.currentDisplayImage = image
//        self.statusDescription = "已成功提取相簿純淨原檔，正在分析..."
//        
//        // 執行自動化管線
//        self.processAutoPipeline(for: image)
//    }
//    
//    
//    private func processAutoPipeline(for image: UIImage) {
//        self.isAnalyzing = true
//        
//        // 🔥 關鍵修正：複製出一張完全獨立、不與外接共享記憶體的純淨圖片，專門給 Vision 偵測
//        guard let cgImageCopy = image.cgImage?.copy() else { return }
//        let imageForDetection = UIImage(cgImage: cgImageCopy, scale: image.scale, orientation: image.imageOrientation)
//        
//        // 用獨立的複製品進行偵測
//        detectionManager.detectFaces(in: imageForDetection, viewSize: nil) { count, rects in
//            self.savedFaceRects = rects
//            self.isAnalyzing = false
//            
//            // 這裡的 count 就絕對會是原圖的精準數量
//            print("👉 [純淨複製品] 偵測到 \(count) 張人臉")
//            
//            var finalProcessedImage = image
//            let lutName = count > 4 ? "resto_people_filter_lut" : "food_filter_lut"
//            
//            if count < 5 {
//                self.isShowDodge = true
//            }
//            
//            // 此時才對「原本的 image」套用濾鏡，兩者互不干擾
//            if let result = filterManager.applyFilter(to: image, lutName: lutName) {
//                finalProcessedImage = result
//                self.statusDescription = "🎉 自動套用濾鏡成功 (\(lutName))"
//            } else {
//                self.statusDescription = "❌ 濾鏡套用失敗，請檢查 Bundle 資源"
//            }
//            
//            // 更新顯示
//            self.originalImage = finalProcessedImage
//            self.currentDisplayImage = finalProcessedImage
//        }
//    }
//    
//    /// 依據點擊次數，對加工後的基底圖進行人臉曝光疊加
//    private func updateImageOutput() {
//        guard let baseImage = originalImage else { return }
//        
//        if exposureCount == 0 {
//            currentDisplayImage = baseImage
//            return
//        }
//        
//        DispatchQueue.global(qos: .userInteractive).async {
//            if let renderedImage = self.dodgeManager.applyFaceDodge(
//                to: baseImage,
//                faceRects: self.savedFaceRects,
//                count: self.exposureCount
//            ) {
//                DispatchQueue.main.async {
//                    self.currentDisplayImage = renderedImage
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    FilterAutoTest()
//}



//
//  FilterAutoTest.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/18.
//

//import SwiftUI
//import PhotosUI
//
//struct FilterAutoTest: View {
//    
//    @State private var faceDetectionTask: Task<Void, Never>? = nil
//    @State private var selectedItem: PhotosPickerItem?
//    
//    @State private var originalImage: UIImage?
//    @State private var currentDisplayImage: UIImage?
//    
//    let detectionManager = FaceDetectionManager()
//    let dodgeManager = FaceDodgeManager()
//    let filterManager = LUTFilterManager()
//    
//    @State private var exposureCount: Int = 0
//    @State private var savedFaceRects: [CGRect] = []
//    @State private var isAnalyzing: Bool = false
//    @State private var isShowDodge: Bool = true // 測試用，預設開啟
//    @State private var statusDescription: String = "請選擇照片"
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 25) {
//                
//                Text("濾鏡自動效果測試")
//                    .font(.title2)
//                    .bold()
//                    .padding(.top)
//                
//                Button("🔥 強制用專案內名為 6 的圖片測試") {
//                    if let image6 = UIImage(named: "6") {
//                        print("===== 橘色按鈕（Assets）數據 =====")
//                        print("UIImage 寬高: \(image6.size.width) x \(image6.size.height)")
//                        print("CGImage 實體像素寬高: \(image6.cgImage?.width ?? 0) x \(image6.cgImage?.height ?? 0)")
//                        print("Scale 縮放率: \(image6.scale)")
//                        
//                        self.isShowDodge = false
//                        self.exposureCount = 0
//                        self.savedFaceRects = []
//                        self.originalImage = image6
//                        self.currentDisplayImage = image6
//                        self.statusDescription = "正在用專案內 6 號圖片測試..."
//                        
//                        self.processAutoPipeline(for: image6)
//                    }
//                }
//                .padding()
//                .background(Color.orange)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//                
//                Text(statusDescription)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                
//                // 1. 影像顯示區
//                if let imageToDisplay = currentDisplayImage {
//                    Image(uiImage: imageToDisplay)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 350)
//                } else {
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color.gray.opacity(0.1))
//                        .frame(height: 350)
//                        .overlay(
//                            VStack(spacing: 10) {
//                                Image(systemName: "photo.on.rectangle")
//                                    .font(.largeTitle)
//                                    .foregroundColor(.gray)
//                                Text("尚未選取照片")
//                                    .foregroundColor(.gray)
//                            }
//                        )
//                        .padding(.horizontal)
//                }
//                
//                // 2. 選擇照片按鈕
//                PhotosPicker(selection: $selectedItem, matching: .images) {
//                    HStack {
//                        Image(systemName: "photo.badge.plus")
//                        Text("選擇照片")
//                    }
//                    .font(.headline)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                    .padding(.horizontal)
//                }
//                .onChange(of: selectedItem) { _, newItem in
//                    Task {
//                        guard let item = newItem else { return }
//                        
//                        guard let data = try? await item.loadTransferable(type: Data.self),
//                              let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
//                            await MainActor.run { self.statusDescription = "❌ 影像資料載入失敗" }
//                            return
//                        }
//                        
//                        // 1. 先獲取正確轉向的原始縮圖影像（設定最大邊緣為 480）
//                        let maxDimension = 480
//                        let options: [CFString: Any] = [
//                            kCGImageSourceCreateThumbnailFromImageAlways: true,
//                            kCGImageSourceCreateThumbnailWithTransform: true,
//                            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
//                            kCGImageSourceShouldCacheImmediately: true
//                        ]
//                        
//                        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
//                            await MainActor.run { self.statusDescription = "❌ 影像正規化失敗" }
//                            return
//                        }
//                        
//                        // 2. 核心物理修正：將影像數據強制重繪，精準鎖定到 480 x 359 解析度，抹平寬高比差異
//                        // 2. 核心物理修正：將影像數據強制重繪，並同步 Assets 的色彩空間與編碼，精準鎖定到 480 x 359 解析度
//                        let targetWidth = 480
//                        let targetHeight = 359
//
//                        guard let alignedCGImage = self.resizeCGImageToMatchAsset(cgImage, toWidth: targetWidth, toHeight: targetHeight) else {
//                            await MainActor.run { self.statusDescription = "❌ 像素對齊失敗" }
//                            return
//                        }
//                        
//                        let finalImage = UIImage(cgImage: alignedCGImage, scale: 1.0, orientation: .up)
//                        
//                        await MainActor.run {
//                            print("===== 物理重繪後相簿數據 =====")
//                            print("UIImage 寬高: \(finalImage.size.width) x \(finalImage.size.height)")
//                            print("CGImage 實體像素寬高: \(finalImage.cgImage?.width ?? 0) x \(finalImage.cgImage?.height ?? 0)")
//                            
//                            self.isShowDodge = false
//                            self.exposureCount = 0
//                            self.savedFaceRects = []
//                            self.originalImage = finalImage
//                            self.currentDisplayImage = finalImage
//                            self.statusDescription = "成功將像素對齊為 480x359 規格，正在分析人臉..."
//                            
//                            self.processAutoPipeline(for: finalImage)
//                        }
//                    }
//                }
//                
//                // 3. 補光按鈕控制區
//                if isShowDodge && currentDisplayImage != nil {
//                    HStack(spacing: 30) {
//                        Button(action: {
//                            if exposureCount > 0 {
//                                exposureCount -= 1
//                                updateImageOutput()
//                            }
//                        }) {
//                            HStack {
//                                Image(systemName: "minus.circle.fill")
//                                Text("取消補光")
//                            }
//                            .font(.subheadline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(exposureCount == 0 ? Color.gray : Color.red)
//                            .cornerRadius(10)
//                        }
//                        .disabled(exposureCount == 0 || isAnalyzing)
//                        
//                        Button(action: {
//                            exposureCount += 1
//                            updateImageOutput()
//                        }) {
//                            HStack {
//                                Image(systemName: "plus.circle.fill")
//                                Text("人臉補光")
//                            }
//                            .font(.subheadline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(isAnalyzing ? Color.gray : Color.blue)
//                            .cornerRadius(10)
//                        }
//                        .disabled(isAnalyzing)
//                    }
//                    .padding(.bottom, 30)
//                }
//            }
//        }
//    }
//    
//    // 輔助函數：將 CGImage 強制重繪至精準的寬高解析度，移除元數據干擾
//    // 1. 升級後的重繪函數：複製 Assets 圖片的基因（色域與編碼格式）
//    private func resizeCGImageToMatchAsset(_ image: CGImage, toWidth width: Int, toHeight height: Int) -> CGImage? {
//        // 嘗試抓取專案內 "6" 號圖片的物理資訊作為絕對標準
//        guard let assetImage = UIImage(named: "6")?.cgImage else {
//            // 如果抓不到，退回到標準 sRGB 與標準無 Alpha 記憶體對齊
//            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
//            let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
//            return drawContext(image, width: width, height: height, colorSpace: colorSpace, bitmapInfo: bitmapInfo)
//        }
//        
//        // 提取 Assets 影像的標準色域與點陣圖資訊
//        let targetColorSpace = assetImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
//        let targetBitmapInfo = assetImage.bitmapInfo.rawValue
//        
//        return drawContext(image, width: width, height: height, colorSpace: targetColorSpace, bitmapInfo: targetBitmapInfo)
//    }
//
//    // 輔助繪製工廠
//    private func drawContext(_ image: CGImage, width: Int, height: Int, colorSpace: CGColorSpace, bitmapInfo: UInt32) -> CGImage? {
//        guard let context = CGContext(
//            data: nil,
//            width: width,
//            height: height,
//            bitsPerComponent: 8,
//            bytesPerRow: width * 4,
//            space: colorSpace,
//            bitmapInfo: bitmapInfo
//        ) else { return nil }
//        
//        context.interpolationQuality = .high
//        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
//        return context.makeImage()
//    }
//    
//    private func executePipeline(with image: UIImage) {
//        self.isShowDodge = false
//        self.exposureCount = 0
//        self.savedFaceRects = []
//        self.originalImage = image
//        self.currentDisplayImage = image
//        self.statusDescription = "已成功提取相簿純淨原檔，正在分析..."
//        
//        self.processAutoPipeline(for: image)
//    }
//    
//    private func processAutoPipeline(for image: UIImage) {
//        self.isAnalyzing = true
//        
//        guard let cgImageCopy = image.cgImage?.copy() else { return }
//        
//        // 💡 核心工程修正：利用 CoreImage 對偵測專用圖進行微幅銳化，補償相簿流的壓縮損失
//        let ciImage = CIImage(cgImage: cgImageCopy)
//        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
//        sharpenFilter?.setValue(ciImage, forKey: kCIInputImageKey)
//        sharpenFilter?.setValue(0.6, forKey: kCIInputSharpnessKey) // 銳化強度設定為 0.6，抓回邊緣細節
//        
//        var finalDetectionImage = image
//        if let outputCIImage = sharpenFilter?.outputImage,
//           let sharpenedCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) {
//            finalDetectionImage = UIImage(cgImage: sharpenedCGImage, scale: image.scale, orientation: image.imageOrientation)
//        } else {
//            finalDetectionImage = UIImage(cgImage: cgImageCopy, scale: image.scale, orientation: image.imageOrientation)
//        }
//        
//        // 用這張經過「細節補償」的純淨複製品進行偵測
//        detectionManager.detectFaces(in: finalDetectionImage, viewSize: nil) { count, rects in
//            self.savedFaceRects = rects
//            self.isAnalyzing = false
//            
//            print("👉 [細節補償複製品] 偵測到 \(count) 張人臉")
//            
//            var finalProcessedImage = image
//            let lutName = count > 4 ? "resto_people_filter_lut" : "food_filter_lut"
//            
//            if count < 5 {
//                self.isShowDodge = true
//            }
//            
//            // 此時對「原本的 image（未銳化、無畫質破壞）」套用 LUT 濾鏡，確保呈現給使用者看的畫面完全乾淨
//            if let result = filterManager.applyFilter(to: image, lutName: lutName) {
//                finalProcessedImage = result
//                self.statusDescription = "🎉 自動套用濾鏡成功 (\(lutName))"
//            } else {
//                self.statusDescription = "❌ 濾鏡套用失敗，請檢查 Bundle 資源"
//            }
//            
//            self.originalImage = finalProcessedImage
//            self.currentDisplayImage = finalProcessedImage
//        }
//    }
//    
//    private func updateImageOutput() {
//        guard let baseImage = originalImage else { return }
//        
//        if exposureCount == 0 {
//            currentDisplayImage = baseImage
//            return
//        }
//        
//        DispatchQueue.global(qos: .userInteractive).async {
//            if let renderedImage = self.dodgeManager.applyFaceDodge(
//                to: baseImage,
//                faceRects: self.savedFaceRects,
//                count: self.exposureCount
//            ) {
//                DispatchQueue.main.async {
//                    self.currentDisplayImage = renderedImage
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    FilterAutoTest()
//}



//
//  FilterAutoTest_VersionB.swift
//  測試：銳化 + 複製 Assets 基因色域（絕對不重繪/不修改像素點）
//

//import SwiftUI
//import PhotosUI
//
//struct FilterAutoTest: View {
//    
//    @State private var selectedItem: PhotosPickerItem?
//    @State private var originalImage: UIImage?
//    @State private var currentDisplayImage: UIImage?
//    
//    let detectionManager = FaceDetectionManager()
//    let filterManager = LUTFilterManager()
//    let dodgeManager = FaceDodgeManager()
//    
//    @State private var exposureCount: Int = 0
//    @State private var savedFaceRects: [CGRect] = []
//    @State private var isAnalyzing: Bool = false
//    @State private var isShowDodge: Bool = true
//    @State private var statusDescription: String = "【版本 B】純色域無損轉換測試"
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 25) {
//                Text("版本 B：銳化 + 純色域置換（不改像素）")
//                    .font(.title3)
//                    .bold()
//                    .padding(.top)
//                
//                Button("🔥 橘色按鈕（Assets 測試）") {
//                    if let image6 = UIImage(named: "6") {
//                        print("===== 橘色按鈕（Assets）數據 =====")
//                        print("UIImage 寬高: \(image6.size.width) x \(image6.size.height)")
//                        print("CGImage 實體像素寬高: \(image6.cgImage?.width ?? 0) x \(image6.cgImage?.height ?? 0)")
//                        
//                        self.resetState(with: image6)
//                        self.processAutoPipeline(for: image6)
//                    }
//                }
//                .padding()
//                .background(Color.orange)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//                
//                Text(statusDescription)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                
//                if let imageToDisplay = currentDisplayImage {
//                    Image(uiImage: imageToDisplay)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 350)
//                }
//                
//                PhotosPicker(selection: $selectedItem, matching: .images) {
//                    Text("選擇照片（實機測試點）")
//                        .font(.headline)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                        .padding(.horizontal)
//                }
//                .onChange(of: selectedItem) { _, newItem in
//                    Task {
//                        guard let item = newItem,
//                              let data = try? await item.loadTransferable(type: Data.self),
//                              let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
//                        
//                        let options: [CFString: Any] = [
//                            kCGImageSourceCreateThumbnailFromImageAlways: true,
//                            kCGImageSourceCreateThumbnailWithTransform: true,
//                            kCGImageSourceThumbnailMaxPixelSize: 480
//                        ]
//                        
//                        // 這是相簿直接解出來的原本縮圖（通常是 480x360）
//                        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { return }
//                        
//                        // 【關鍵測試點 B】：絕對不開繪圖 Context。直接抓取 Assets "6" 的色域。
//                        // 如果抓不到，則使用標準 sRGB 色域。
//                        let targetColorSpace = UIImage(named: "6")?.cgImage?.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
//                        
//                        // 利用 copy(colorSpace:) 直接置換色域指標，點陣圖像素結構與記憶體完全不動
//                        guard let colorSpaceMappedCGImage = cgImage.copy(colorSpace: targetColorSpace) else { return }
//                        
//                        let finalImage = UIImage(cgImage: colorSpaceMappedCGImage, scale: 1.0, orientation: .up)
//                        
//                        await MainActor.run {
//                            print("===== 【版本 B】實機相簿數據 =====")
//                            print("UIImage 寬高: \(finalImage.size.width) x \(finalImage.size.height)")
//                            print("CGImage 實體像素寬高: \(finalImage.cgImage?.width ?? 0) x \(finalImage.cgImage?.height ?? 0)")
//                            
//                            self.resetState(with: finalImage)
//                            self.processAutoPipeline(for: finalImage)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private func resetState(with image: UIImage) {
//        self.isShowDodge = false
//        self.exposureCount = 0
//        self.savedFaceRects = []
//        self.originalImage = image
//        self.currentDisplayImage = image
//    }
//    
//    private func processAutoPipeline(for image: UIImage) {
//        self.isAnalyzing = true
//        guard let cgImageCopy = image.cgImage?.copy() else { return }
//        
//        // 偵測端專用銳化管線
//        let ciImage = CIImage(cgImage: cgImageCopy)
//        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
//        sharpenFilter?.setValue(ciImage, forKey: kCIInputImageKey)
//        sharpenFilter?.setValue(0.6, forKey: kCIInputSharpnessKey)
//        
//        var finalDetectionImage = image
//        if let outputCIImage = sharpenFilter?.outputImage,
//           let sharpenedCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) {
//            finalDetectionImage = UIImage(cgImage: sharpenedCGImage, scale: image.scale, orientation: image.imageOrientation)
//        }
//        
//        detectionManager.detectFaces(in: finalDetectionImage, viewSize: nil) { count, rects in
//            self.savedFaceRects = rects
//            self.isAnalyzing = false
//            print("👉 【版本 B】偵測到 \(count) 張人臉")
//            
//            let lutName = count > 4 ? "resto_people_filter_lut" : "food_filter_lut"
//            if count < 5 { self.isShowDodge = true }
//            
//            if let result = filterManager.applyFilter(to: image, lutName: lutName) {
//                self.originalImage = result
//                self.currentDisplayImage = result
//                self.statusDescription = "🎉 自動套用濾鏡：\(lutName)"
//            }
//        }
//    }
//}



//
//  FilterAutoTest_PureColorSpace.swift
//  測試：純色域無損轉換（無銳化、不修改像素點）
//
//
//import SwiftUI
//import PhotosUI
//
//struct FilterAutoTest: View {
//    
//    @State private var selectedItem: PhotosPickerItem?
//    @State private var originalImage: UIImage?
//    @State private var currentDisplayImage: UIImage?
//    
//    let detectionManager = FaceDetectionManager()
//    let filterManager = LUTFilterManager()
//    let dodgeManager = FaceDodgeManager()
//    
//    @State private var exposureCount: Int = 0
//    @State private var savedFaceRects: [CGRect] = []
//    @State private var isAnalyzing: Bool = false
//    @State private var isShowDodge: Bool = true
//    @State private var statusDescription: String = "【純色域版】無銳化對照測試"
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 25) {
//                Text("純色域版：無銳化 + 純色域置換")
//                    .font(.title3)
//                    .bold()
//                    .padding(.top)
//                
//                Button("🔥 橘色按鈕（Assets 測試）") {
//                    if let image6 = UIImage(named: "6") {
//                        print("===== 橘色按鈕（Assets）數據 =====")
//                        print("UIImage 寬高: \(image6.size.width) x \(image6.size.height)")
//                        print("CGImage 實體像素寬高: \(image6.cgImage?.width ?? 0) x \(image6.cgImage?.height ?? 0)")
//                        
//                        self.resetState(with: image6)
//                        self.processAutoPipeline(for: image6)
//                    }
//                }
//                .padding()
//                .background(Color.orange)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//                
//                Text(statusDescription)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                
//                if let imageToDisplay = currentDisplayImage {
//                    Image(uiImage: imageToDisplay)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 350)
//                }
//                
//                PhotosPicker(selection: $selectedItem, matching: .images) {
//                    Text("選擇照片（實機測試點）")
//                        .font(.headline)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                        .padding(.horizontal)
//                }
//                .onChange(of: selectedItem) { _, newItem in
//                    Task {
//                        guard let item = newItem,
//                              let data = try? await item.loadTransferable(type: Data.self),
//                              let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
//                        
//                        let options: [CFString: Any] = [
//                            kCGImageSourceCreateThumbnailFromImageAlways: true,
//                            kCGImageSourceCreateThumbnailWithTransform: true,
//                            kCGImageSourceThumbnailMaxPixelSize: 480
//                        ]
//                        
//                        // 1. 取得相簿原始縮圖
//                        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { return }
//                        
//                        // 2. 獲取 Assets "6" 的目標色域（若無則改用標準 sRGB）
//                        let targetColorSpace = UIImage(named: "6")?.cgImage?.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
//                        
//                        // 3. 純色域變更：無損轉換色彩對照矩陣，不重新繪製，不改動像素維度與內容
//                        guard let colorSpaceMappedCGImage = cgImage.copy(colorSpace: targetColorSpace) else { return }
//                        
//                        let finalImage = UIImage(cgImage: colorSpaceMappedCGImage, scale: 1.0, orientation: .up)
//                        
//                        await MainActor.run {
//                            print("===== 【純色域版】實機相簿數據 =====")
//                            print("UIImage 寬高: \(finalImage.size.width) x \(finalImage.size.height)")
//                            print("CGImage 實體像素寬高: \(finalImage.cgImage?.width ?? 0) x \(finalImage.cgImage?.height ?? 0)")
//                            
//                            self.resetState(with: finalImage)
//                            self.processAutoPipeline(for: finalImage)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private func resetState(with image: UIImage) {
//        self.isShowDodge = false
//        self.exposureCount = 0
//        self.savedFaceRects = []
//        self.originalImage = image
//        self.currentDisplayImage = image
//    }
//    
//    private func processAutoPipeline(for image: UIImage) {
//        self.isAnalyzing = true
//        
//        // 此版本直接將沒有經過任何銳化處理的原始 image 丟給偵測引擎
//        detectionManager.detectFaces(in: image, viewSize: nil) { count, rects in
//            self.savedFaceRects = rects
//            self.isAnalyzing = false
//            print("👉 【純色域版】偵測到 \(count) 張人臉")
//            
//            let lutName = count > 4 ? "resto_people_filter_lut" : "food_filter_lut"
//            if count < 5 { self.isShowDodge = true }
//            
//            if let result = filterManager.applyFilter(to: image, lutName: lutName) {
//                self.originalImage = result
//                self.currentDisplayImage = result
//                self.statusDescription = "🎉 自動套用濾鏡：\(lutName)"
//            }
//        }
//    }
//}


//import SwiftUI
//import PhotosUI
//
//struct FilterAutoTest: View {
//    
//    // --- 狀態變數 ---
//    @State private var selectedItem: PhotosPickerItem?
//    @State private var originalImage: UIImage?
//    @State private var currentDisplayImage: UIImage?
//    
//    // --- 管理器 ---
//    let detectionManager = FaceDetectionManager()
//    let dodgeManager = FaceDodgeManager()
//    let filterManager = LUTFilterManager()
//    
//    // --- 功能變數 ---
//    @State private var exposureCount: Int = 0
//    @State private var savedFaceRects: [CGRect] = []
//    @State private var isAnalyzing: Bool = false
//    @State private var isShowDodge: Bool = false
//    @State private var statusDescription: String = "請選擇照片進行測試"
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 25) {
////                Text("濾鏡自動偵測與補光測試")
////                    .font(.title2)
////                    .bold()
////                    .padding(.top)
////                
////                // 1. 測試按鈕
////                Button("🔥 強制使用 Assets \"6\" 測試") {
////                    if let image6 = UIImage(named: "6") {
////                        self.processImage(image6, isFromPicker: false)
////                    }
////                }
////                .padding()
////                .background(Color.orange)
////                .foregroundColor(.white)
////                .cornerRadius(10)
////                
////                Text(statusDescription)
////                    .font(.subheadline)
////                    .foregroundColor(.gray)
//                
//                // 2. 圖片顯示區
//                if let imageToDisplay = currentDisplayImage {
//                    Image(uiImage: imageToDisplay)
////                        .resizable()
////                        .scaledToFit()
////                        .frame(maxWidth: .infinity)
//                } else {
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color.gray.opacity(0.1))
//                        .frame(height: 700)
//                        .overlay(Text("尚未選擇照片").foregroundColor(.gray))
//                        .padding(.horizontal)
//                }
//                
//                // 3. 選擇照片
//                PhotosPicker(selection: $selectedItem, matching: .images) {
//                    HStack {
//                        Image(systemName: "photo.badge.plus")
//                        Text("選擇照片")
//                    }
//                    .font(.headline)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .glassEffect()
//                    .padding(.horizontal)
//                }
//                .onChange(of: selectedItem) { _, newItem in
//                    Task {
//                        guard let item = newItem,
//                              let data = try? await item.loadTransferable(type: Data.self),
//                              let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
//                        
//                        let options: [CFString: Any] = [
//                            kCGImageSourceCreateThumbnailFromImageAlways: true,
//                            kCGImageSourceCreateThumbnailWithTransform: true,
//                            kCGImageSourceThumbnailMaxPixelSize: 480
//                        ]
//                        
//                        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { return }
//                        
//                        // 【關鍵：色域對齊】直接無損置換色域，保持像素結構完整
//                        let targetColorSpace = UIImage(named: "6")?.cgImage?.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
//                        guard let colorSpaceMappedCGImage = cgImage.copy(colorSpace: targetColorSpace) else { return }
//                        
//                        let finalImage = UIImage(cgImage: colorSpaceMappedCGImage, scale: 1.0, orientation: .up)
//                        
//                        await MainActor.run { self.processImage(finalImage, isFromPicker: true) }
//                    }
//                }
//                
//                // 4. 補光控制區
//                if isShowDodge && currentDisplayImage != nil {
//                    HStack(spacing: 30) {
//                        Button(action: { if exposureCount > 0 { exposureCount -= 1; updateImageOutput() } }) {
//                            Label("取消補光", systemImage: "minus.circle.fill")
//                                .padding()
//                                .background(exposureCount == 0 ? Color.gray : Color.red)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                        }
//                        .disabled(exposureCount == 0 || isAnalyzing)
//                        
//                        Button(action: { exposureCount += 1; updateImageOutput() }) {
//                            Label("人臉補光", systemImage: "plus.circle.fill")
//                                .padding()
//                                .background(isAnalyzing ? Color.gray : Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                        }
//                        .disabled(isAnalyzing)
//                    }
//                    .padding(.bottom, 30)
//                }
//            }
//        }
//        .ignoresSafeArea(.all).background(Color.init(cgColor: .init(gray: 0.9, alpha: 1)))
//    }
//        
//    
//    // --- 核心邏輯處理 ---
//    private func processImage(_ image: UIImage, isFromPicker: Bool) {
//        self.isShowDodge = false
//        self.exposureCount = 0
//        self.savedFaceRects = []
//        self.originalImage = image
//        self.currentDisplayImage = image
//        self.statusDescription = isFromPicker ? "相簿照片已讀取，處理中..." : "Assets 照片已讀取，處理中..."
//        
//        //processAutoPipeline(for: image)
//        
//        // 🎯 使用 Task 包裹非同步呼叫，並補上 await
//        Task {
//            await self.processAutoPipeline(for: image)
//        }
//        
//    }
//    
////    private func processAutoPipeline(for image: UIImage) {
////        self.isAnalyzing = true
////
////        // 【關鍵：偵測端銳化】建立銳化複製品，僅供偵測使用
////        guard let cgImageCopy = image.cgImage?.copy() else { return }
////        let ciImage = CIImage(cgImage: cgImageCopy)
////        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
////        sharpenFilter?.setValue(ciImage, forKey: kCIInputImageKey)
////        sharpenFilter?.setValue(0.6, forKey: kCIInputSharpnessKey) // 銳化程度
////        
////        var finalDetectionImage = image
////        if let outputCIImage = sharpenFilter?.outputImage,
////           let sharpenedCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) {
////            finalDetectionImage = UIImage(cgImage: sharpenedCGImage, scale: image.scale, orientation: image.imageOrientation)
////        }
////        
////        // 執行偵測
////        detectionManager.detectFaces(in: finalDetectionImage, viewSize: nil) { count, rects in
////            self.savedFaceRects = rects
////            self.isAnalyzing = false
////            
////            // 套用濾鏡
////            let lutName = count > 4 ? "resto_people_filter_lut" : "food_filter_lut"
////            if count < 5 { self.isShowDodge = true }
////            
////            // 這裡套用濾鏡使用的是原始乾淨的 image
////            if let result = filterManager.applyFilter(to: image, lutName: lutName) {
////                self.originalImage = result
////                self.currentDisplayImage = result
////                self.statusDescription = "✅ 完成：偵測到 \(count) 張人臉，套用 \(lutName)"
////            } else {
////                self.statusDescription = "❌ 濾鏡套用失敗"
////            }
////        }
////    }
//    
//    private func processAutoPipeline(for image: UIImage) async {
//        self.isAnalyzing = true
//        
//        // 🎯 在管線中直接提取並印出
//        if let hsb = await image.getDominantColorHSB() {
//            print("🔮 Pipeline 測試 -> H: \(hsb.hue), S: \(hsb.saturation), B: \(hsb.brightness)")
//            
//            // 在這裡做你的新版條件測試
//            // 在接收時就把 hue, saturation, brightness 拆出來
//            if let (hue, saturation, brightness) = await image.getDominantColorHSB() {
//                
//                // 🎯 這樣你原本的這段程式碼就完全合法、不會報錯了！
//                let isBrownish = (hue >= 0.0 && hue <= 0.15) &&
//                                 (saturation >= 0.35) &&
//                                 (brightness >= 0.15 && brightness <= 0.3)
//                                 
//                if isBrownish {
//                    print("確認為棕色")
//                }
//            }
//        }
//        
//        // 【偵測端專用銳化】建立銳化複製品，僅供 Vision 偵測使用
//        guard let cgImageCopy = image.cgImage?.copy() else { return }
//        let ciImage = CIImage(cgImage: cgImageCopy)
//        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
//        sharpenFilter?.setValue(ciImage, forKey: kCIInputImageKey)
//        sharpenFilter?.setValue(0.6, forKey: kCIInputSharpnessKey) // 銳化強度
//        
//        var finalDetectionImage = image
//        if let outputCIImage = sharpenFilter?.outputImage,
//           let sharpenedCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) {
//            finalDetectionImage = UIImage(cgImage: sharpenedCGImage, scale: image.scale, orientation: image.imageOrientation)
//        }
//        
//        // 1. 執行人臉偵測（此處為後台 Callback）
//        detectionManager.detectFaces(in: finalDetectionImage, viewSize: nil) { count, rects in
//            
//            // 2. 開啟非同步 Task，在背景同時處理「顏色分析」與「濾鏡套用」
//            Task {
//                self.savedFaceRects = rects
//                
//                // 3. 【關鍵時機】在套用濾鏡前，提取原圖真實主色並判定是否為深咖啡色
//                let isDarkBrown = await image.checkIsDominantColorDarkBrown()
//                
//                // 4. 依據判定結果，動態決定要使用的 LUT 濾鏡名稱
//                var lutName = "gray_filter_lut" // 預設濾鏡
//                
//                if isDarkBrown {
//                    if (1...4).contains(count) {
//                        lutName = "food_filter_lut" // 🪵 偵測到深咖啡色時套用的特定濾鏡
//                        print("🎨 顏色判定結果：深咖啡色 ➔ 選擇濾鏡：\(lutName)")
//                        await MainActor.run { self.isShowDodge = true } // 調整補光按鈕顯示狀態（需切回主線程更新 UI 狀態）
//                    } else if count > 4{
//                        lutName = "resto_people_filter_lut"
//                        print("🎨 顏色判定結果：深咖啡色 ➔ 選擇濾鏡：\(lutName)")
//                    } else {
//                        lutName = "food_filter_lut"
//                        print("🎨 顏色判定結果：深咖啡色 ➔ 選擇濾鏡：\(lutName)")
//                    }
//                    
//                } else {
//                    lutName = "gray_filter_lut"
//                    print("🎨 顏色判定結果：非深咖啡色 ➔ 依據人臉數選擇濾鏡：\(lutName)")
//                }
//                
//                
//                
//                // 5. 【背景運算】對原始乾淨的 image 套用濾鏡
//                if let result = self.filterManager.applyFilter(to: image, lutName: lutName) {
//                    
//                    // 6. 【更新 UI】濾鏡完工，切回主線程更換螢幕上的照片與文字
//                    await MainActor.run {
//                        self.isAnalyzing = false
//                        self.originalImage = result         // 換上加工後的照片作為基底
//                        self.currentDisplayImage = result  // 更新畫面上顯示的照片
//                        self.statusDescription = "🎉 自動套用濾鏡：\(lutName)"
//                    }
//                } else {
//                    // 濾鏡失敗的 UI 處理
//                    await MainActor.run {
//                        self.isAnalyzing = false
//                        self.statusDescription = "❌ 濾鏡套用失敗"
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    private func updateImageOutput() {
//        guard let baseImage = originalImage else { return }
//        
//        if exposureCount == 0 {
//            currentDisplayImage = baseImage
//            return
//        }
//        
//        DispatchQueue.global(qos: .userInteractive).async {
//            if let renderedImage = self.dodgeManager.applyFaceDodge(to: baseImage, faceRects: self.savedFaceRects, count: self.exposureCount) {
//                DispatchQueue.main.async { self.currentDisplayImage = renderedImage }
//            }
//        }
//    }
//}
//
//
//
//
//
//#Preview {
//    FilterAutoTest()
//}


//
//import SwiftUI
//import PhotosUI
//
//struct FilterAutoTest: View {
//    
//    // --- 狀態變數 ---
//    @State private var selectedItem: PhotosPickerItem?
//    
//    // 💡 核心修正：將圖層基底徹底分離
//    @State private var pureOriginalImage: UIImage?      // 儲存完全沒有濾鏡的「絕對原圖」
//    @State private var filteredImage: UIImage?          // 儲存套用 LUT 濾鏡後的基礎圖
//    @State private var isFilterApplied: Bool = true     // 紀錄目前是否要啟用濾鏡效果
//    
//    @State private var originalImage: UIImage?          // 舊有相容變數
//    @State private var currentDisplayImage: UIImage?    // 最終呈現給使用者看的畫面
//    
//    // --- 管理器 ---
//    let detectionManager = FaceDetectionManager()
//    let dodgeManager = FaceDodgeManager()
//    let filterManager = LUTFilterManager()
//    
//    // --- 功能變數 ---
//    @State private var exposureCount: Int = 0
//    @State private var savedFaceRects: [CGRect] = []
//    @State private var isAnalyzing: Bool = false
//    @State private var isShowDodge: Bool = false
//    @State private var statusDescription: String = "請選擇照片進行測試"
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 25) {
//                
//                // 1. 圖片顯示區
//                if let imageToDisplay = currentDisplayImage {
//                    Image(uiImage: imageToDisplay)
//                        .resizable()
//                        .scaledToFit()
//                } else {
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color.gray.opacity(0.1))
//                        .frame(height: 700)
//                        .overlay(Text("尚未選擇照片").foregroundColor(.gray))
//                        .padding(.horizontal)
//                }
//                
//                // 2. 選擇照片
//                PhotosPicker(selection: $selectedItem, matching: .images) {
//                    HStack {
//                        Image(systemName: "photo.badge.plus")
//                        Text("選擇照片")
//                    }
//                    .font(.headline)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .glassEffect()
//                    .padding(.horizontal)
//                }
////                .onChange(of: selectedItem) { _, newItem in
////                    Task {
////                        guard let item = newItem,
////                              let data = try? await item.loadTransferable(type: Data.self),
////                              let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
////                        // 🎯 將 480 改為 2000，供應 Retina 螢幕足夠的實體像素
////                        let options: [CFString: Any] = [
////                            kCGImageSourceCreateThumbnailFromImageAlways: true,
////                            kCGImageSourceCreateThumbnailWithTransform: true,
////                            kCGImageSourceThumbnailMaxPixelSize: 2000,
////                            kCGImageSourceShouldCacheImmediately: true
////                        ]
//////                        let options: [CFString: Any] = [
//////                            kCGImageSourceCreateThumbnailFromImageAlways: true,
//////                            kCGImageSourceCreateThumbnailWithTransform: true,
//////                            kCGImageSourceThumbnailMaxPixelSize: 480
//////                        ]
////                        
////                        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { return }
////                        
//////                        let targetColorSpace = UIImage(named: "6")?.cgImage?.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
//////                        guard let colorSpaceMappedCGImage = cgImage.copy(colorSpace: targetColorSpace) else { return }
////                        
////                        
////                        // 2. 🎯 乾淨的色域處理：不再依賴任何圖片檔案，直接使用標準 sRGB
////                        // 如果 sRGB 無法建立，則回退到裝置預設 RGB
////                        let targetColorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
////                        
////                        guard let colorSpaceMappedCGImage = cgImage.copy(colorSpace: targetColorSpace) else {
////                            print("❌ 色域轉換失敗")
////                            return
////                        }
////                        //
////                        
////                        let finalImage = UIImage(cgImage: colorSpaceMappedCGImage, scale: 1.0, orientation: .up)
////                        
////                        await MainActor.run { self.processImage(finalImage, isFromPicker: true) }
////                    }
////                }
//                
//                .onChange(of: selectedItem) { _, newItem in
//                    Task {
//                        guard let item = newItem,
//                              let data = try? await item.loadTransferable(type: Data.self),
//                              let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
//                        
//                        // 1. 解碼一張 2000px 的圖（用於顯示與濾鏡）
//                        let options2000: [CFString: Any] = [
//                            kCGImageSourceCreateThumbnailFromImageAlways: true,
//                            kCGImageSourceCreateThumbnailWithTransform: true,
//                            kCGImageSourceThumbnailMaxPixelSize: 2000,
//                            kCGImageSourceShouldCacheImmediately: true
//                        ]
//                        
//                        // 2. 解碼一張 480px 的圖（用於 Vision 偵測，這是您測試成功過的來源）
//                        let options480: [CFString: Any] = [
//                            kCGImageSourceCreateThumbnailFromImageAlways: true,
//                            kCGImageSourceCreateThumbnailWithTransform: true,
//                            kCGImageSourceThumbnailMaxPixelSize: 480, // 👈 精確匹配您成功的參數
//                            kCGImageSourceShouldCacheImmediately: true
//                        ]
//                        
//                        guard let cgImage2000 = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options2000 as CFDictionary),
//                              let cgImage480 = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options480 as CFDictionary) else { return }
//                        
//                        // 色域處理（使用 sRGB）
//                        let targetColorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
//                        
//                        guard let finalCG2000 = cgImage2000.copy(colorSpace: targetColorSpace),
//                              let finalCG480 = cgImage480.copy(colorSpace: targetColorSpace) else { return }
//                        
//                        let displayImage = UIImage(cgImage: finalCG2000, scale: 1.0, orientation: .up)
//                        let detectionImage = UIImage(cgImage: finalCG480, scale: 1.0, orientation: .up)
//                        
//                        // 3. 傳遞給後續處理
//                        await MainActor.run {
//                            // 呼叫修正後的雙管線處理函式
//                            self.processDualImage(displayImage: displayImage, detectionImage: detectionImage)
//                        }
//                    }
//                }
//                
//                
//                // 🔥 3. 新增：濾鏡控制按鈕區
//                if currentDisplayImage != nil {
//                    HStack(spacing: 20) {
//                        // 取消濾鏡按鈕
//                        Button(action: {
//                            isFilterApplied = false
//                            updateImageOutput()
//                        }) {
//                            HStack {
//                                Image(systemName: "slider.horizontal.3")
//                                Text("取消濾鏡效果")
//                            }
//                            .font(.subheadline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(!isFilterApplied ? Color.gray : Color.red)
//                            .cornerRadius(10)
//                        }
//                        .disabled(!isFilterApplied || isAnalyzing)
//                        
//                        // 復原濾鏡按鈕
//                        Button(action: {
//                            isFilterApplied = true
//                            updateImageOutput()
//                        }) {
//                            HStack {
//                                Image(systemName: "arrow.uturn.backward")
//                                Text("復原濾鏡效果")
//                            }
//                            .font(.subheadline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(isFilterApplied ? Color.gray : Color.green)
//                            .cornerRadius(10)
//                        }
//                        .disabled(isFilterApplied || isAnalyzing)
//                    }
//                    .padding(.horizontal)
//                }
//                
//                // 4. 補光控制區
//                if isShowDodge && currentDisplayImage != nil {
//                    HStack(spacing: 30) {
//                        Button(action: { if exposureCount > 0 { exposureCount -= 1; updateImageOutput() } }) {
//                            Label("取消補光", systemImage: "minus.circle.fill")
//                                .padding()
//                                .background(exposureCount == 0 ? Color.gray : Color.red)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                        }
//                        .disabled(exposureCount == 0 || isAnalyzing)
//                        
//                        Button(action: { exposureCount += 1; updateImageOutput() }) {
//                            Label("人臉補光", systemImage: "plus.circle.fill")
//                                .padding()
//                                .background(isAnalyzing ? Color.gray : Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                        }
//                        .disabled(isAnalyzing)
//                    }
//                    .padding(.bottom, 30)
//                }
//            }
//        }
//        .background(Color.init(cgColor: .init(gray: 0.9, alpha: 1)))
//    }
//        
//    // --- 核心邏輯處理 ---
//    private func processImage(_ image: UIImage, isFromPicker: Bool) {
//        self.isShowDodge = false
//        self.exposureCount = 0
//        self.savedFaceRects = []
//        
//        // 💡 初始化時同步更新純淨原圖與濾鏡狀態
//        self.pureOriginalImage = image
//        self.filteredImage = nil
//        self.isFilterApplied = true
//        
//        self.originalImage = image
//        self.currentDisplayImage = image
//        self.statusDescription = isFromPicker ? "相簿照片已讀取，處理中..." : "Assets 照片已讀取，處理中..."
//        
//        Task {
//            //await self.processAutoPipeline(for: image)
//            // 💡 同步更新為新的參數名稱，傳入兩張圖
//            await self.processAutoPipeline(displayImage: displayImage, detectionImage: detectionImage)
//        }
//    }
//    
//   
//    
////    private func processAutoPipeline(for image: UIImage) async {
////        self.isAnalyzing = true
////        
////        if let (hue, saturation, brightness) = await image.getDominantColorHSB() {
////            let isBrownish = (hue >= 0.0 && hue <= 0.15) &&
////                             (saturation >= 0.35) &&
////                             (brightness >= 0.15 && brightness <= 0.3)
////                                 
////            if isBrownish {
////                print("確認為棕色")
////            }
////        }
////        
////        guard let cgImageCopy = image.cgImage?.copy() else { return }
////        let ciImage = CIImage(cgImage: cgImageCopy)
////        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
////        sharpenFilter?.setValue(ciImage, forKey: kCIInputImageKey)
////        sharpenFilter?.setValue(0.6, forKey: kCIInputSharpnessKey)
////        
////        var finalDetectionImage = image
////        if let outputCIImage = sharpenFilter?.outputImage,
////           let sharpenedCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) {
////            finalDetectionImage = UIImage(cgImage: sharpenedCGImage, scale: image.scale, orientation: image.imageOrientation)
////        }
////        
////        detectionManager.detectFaces(in: finalDetectionImage, viewSize: nil) { count, rects in
////            Task {
////                self.savedFaceRects = rects
////                let isDarkBrown = await image.checkIsDominantColorDarkBrown()
////                var lutName = "gray_filter_lut"
////                print(count)
////                if isDarkBrown {
////                    if (1...4).contains(count) {
////                        lutName = "food_filter_lut"
////                        await MainActor.run { self.isShowDodge = true }
////                    } else if count > 4 {
////                        lutName = "resto_people_filter_lut"
////                    } else {
////                        lutName = "food_filter_lut"
////                    }
////                } else {
////                    lutName = "gray_filter_lut"
////                }
////                
////                if let result = self.filterManager.applyFilter(to: image, lutName: lutName) {
////                    await MainActor.run {
////                        self.isAnalyzing = false
////                        // 💡 核心修正：將濾鏡圖存入獨立變數，不再無條件覆蓋 originalImage
////                        self.filteredImage = result
////                        self.statusDescription = "🎉 自動套用濾鏡：\(lutName)"
////                        self.updateImageOutput()
////                    }
////                } else {
////                    await MainActor.run {
////                        self.isAnalyzing = false
////                        self.statusDescription = "❌ 濾鏡套用失敗"
////                        self.updateImageOutput()
////                    }
////                }
////            }
////        }
////    }
//    private func processAutoPipeline(displayImage: UIImage, detectionImage: UIImage) async {
//        // 1. 開始分析，初始化狀態
//        await MainActor.run { self.isAnalyzing = true }
//        
//        // 2. 專門針對偵測影像進行銳化 (僅影響偵測準確度，不影響畫質)
//        var finalDetectionImage = detectionImage
//        if let cgImage = detectionImage.cgImage {
//            let ciImage = CIImage(cgImage: cgImage)
//            let sharpenFilter = CIFilter(name: "CISharpenLuminance")
//            sharpenFilter?.setValue(ciImage, forKey: kCIInputImageKey)
//            sharpenFilter?.setValue(0.6, forKey: kCIInputSharpnessKey)
//            
//            if let outputCIImage = sharpenFilter?.outputImage,
//               let sharpenedCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) {
//                finalDetectionImage = UIImage(cgImage: sharpenedCGImage, scale: detectionImage.scale, orientation: detectionImage.imageOrientation)
//            }
//        }
//        
//        // 3. 執行人臉偵測
//        detectionManager.detectFaces(in: finalDetectionImage, viewSize: nil) { count, rects in
//            Task {
//                self.savedFaceRects = rects
//                
//                // 4. 使用 detectionImage 分析顏色 (效能更好)
//                let isDarkBrown = await detectionImage.checkIsDominantColorDarkBrown()
//                var lutName = "gray_filter_lut"
//                
//                if isDarkBrown {
//                    if (1...4).contains(count) {
//                        lutName = "food_filter_lut"
//                        await MainActor.run { self.isShowDodge = true }
//                    } else if count > 4 {
//                        lutName = "resto_people_filter_lut"
//                    } else {
//                        lutName = "food_filter_lut"
//                    }
//                } else {
//                    lutName = "gray_filter_lut"
//                }
//                
//                // 5. 套用濾鏡 (針對 2000px 的 displayImage)
//                if let filteredResult = self.filterManager.applyFilter(to: displayImage, lutName: lutName) {
//                    
//                    // 6. 若偵測到人臉，執行補光 (補光應在高畫質圖上執行)
//                    var finalResult = filteredResult
//                    if count > 0 {
//                        // 請務必確認此處的 faceDodgeManager 變數名稱與你的宣告一致
//                        if let dodgedImage = self.dodgeManager.applyFaceDodge(to: filteredResult, faceRects: rects, count: count) {
//                            finalResult = dodgedImage
//                        }
//                    }
//                    
//                    await MainActor.run {
//                        self.isAnalyzing = false
//                        self.filteredImage = finalResult
//                        self.statusDescription = "🎉 自動套用濾鏡：\(lutName)"
//                        self.updateImageOutput()
//                    }
//                } else {
//                    await MainActor.run {
//                        self.isAnalyzing = false
//                        self.statusDescription = "❌ 濾鏡套用失敗"
//                        self.updateImageOutput()
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    
//    
//    
//    private func updateImageOutput() {
//        // 💡 核心修正：動態決定基底圖。啟用濾鏡時使用 filteredImage（若未生成則回退），關閉濾鏡時使用 pureOriginalImage
//        let baseImage: UIImage
//        if isFilterApplied {
//            baseImage = filteredImage ?? pureOriginalImage ?? originalImage ?? UIImage()
//        } else {
//            baseImage = pureOriginalImage ?? originalImage ?? UIImage()
//        }
//        
//        if baseImage.size == .zero { return }
//        
//        if exposureCount == 0 {
//            currentDisplayImage = baseImage
//            return
//        }
//        
//        DispatchQueue.global(qos: .userInteractive).async {
//            if let renderedImage = self.dodgeManager.applyFaceDodge(to: baseImage, faceRects: self.savedFaceRects, count: self.exposureCount) {
//                DispatchQueue.main.async {
//                    self.currentDisplayImage = renderedImage
//                }
//            }
//        }
//    }
//}
//
//
//#Preview {
//    FilterAutoTest()
//}


import SwiftUI
import PhotosUI

struct FilterAutoTest: View {
    
    // --- 狀態變數 ---
    @State private var selectedItem: PhotosPickerItem?
    
    // 💡 圖層基底分離
    @State private var pureOriginalImage: UIImage?      // 絕對原圖
    @State private var filteredImage: UIImage?          // 濾鏡結果圖
    @State private var isFilterApplied: Bool = true     // 濾鏡啟用開關
    
    @State private var originalImage: UIImage?          // 舊有相容
    @State private var currentDisplayImage: UIImage?    // 最終顯示圖
    
    // --- 管理器 ---
    let detectionManager = FaceDetectionManager()
    let dodgeManager = FaceDodgeManager()
    let filterManager = LUTFilterManager()
    
    // --- 功能變數 ---
    @State private var exposureCount: Int = 0
    @State private var savedFaceRects: [CGRect] = []
    @State private var isAnalyzing: Bool = false
    @State private var isShowDodge: Bool = false
    @State private var statusDescription: String = "請選擇照片進行測試"

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                
                // 1. 圖片顯示區
                if let imageToDisplay = currentDisplayImage {
                    Image(uiImage: imageToDisplay)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 400)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 400)
                        .overlay(Text("尚未選擇照片").foregroundColor(.gray))
                        .padding(.horizontal)
                }
                
                Text(statusDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // 2. 選擇照片
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("選擇照片")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect()
                    .padding(.horizontal)
                }
                // ✅ 修正：使用 iOS 17+ 的雙參數寫法
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        guard let item = newItem,
                              let data = try? await item.loadTransferable(type: Data.self),
                              let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return }
                        
                        // 解碼 2000px (顯示/濾鏡) 與 480px (偵測)
                        let options2000: [CFString: Any] = [
                            kCGImageSourceCreateThumbnailFromImageAlways: true,
                            kCGImageSourceCreateThumbnailWithTransform: true,
                            kCGImageSourceThumbnailMaxPixelSize: 2000,
                            kCGImageSourceShouldCacheImmediately: true
                        ]
                        let options480: [CFString: Any] = [
                            kCGImageSourceCreateThumbnailFromImageAlways: true,
                            kCGImageSourceCreateThumbnailWithTransform: true,
                            kCGImageSourceThumbnailMaxPixelSize: 480,
                            kCGImageSourceShouldCacheImmediately: true
                        ]
                        
                        guard let cgImage2000 = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options2000 as CFDictionary),
                              let cgImage480 = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options480 as CFDictionary) else { return }
                        
                        let targetColorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
                        
                        guard let finalCG2000 = cgImage2000.copy(colorSpace: targetColorSpace),
                              let finalCG480 = cgImage480.copy(colorSpace: targetColorSpace) else { return }
                        
                        let displayImage = UIImage(cgImage: finalCG2000, scale: 1.0, orientation: .up)
                        let detectionImage = UIImage(cgImage: finalCG480, scale: 1.0, orientation: .up)
                        
                        // ✅ 修正：在此直接呼叫處理函數，確保 Scope 正確
                        await MainActor.run {
                            self.processDualPipeline(displayImage: displayImage, detectionImage: detectionImage)
                        }
                    }
                }
                
                // 3. 濾鏡與補光控制
                if currentDisplayImage != nil {
                    VStack(spacing: 15) {
                        HStack(spacing: 20) {
                            Button("取消濾鏡") { isFilterApplied = false; updateImageOutput() }
                                .padding().tint(!isFilterApplied ? Color.gray : Color.red).glassEffect()
                            Button("復原濾鏡") { isFilterApplied = true; updateImageOutput() }
                                .padding().tint(isFilterApplied ? Color.gray : Color.green).glassEffect()
                        }
                        
                        if isShowDodge {
                            HStack(spacing: 30) {
                                Button("取消補光") { if exposureCount > 0 { exposureCount -= 1; updateImageOutput() } }
                                    .padding().glassEffect().tint(exposureCount == 0 ? Color.gray : Color.red)
                                Button("人臉補光") { exposureCount += 1; updateImageOutput() }
                                    .padding().glassEffect().tint(isAnalyzing ? Color.gray : Color.blue)
                            }
                        }
                    }.font(.footnote)
                }
            }
        }
        .background(Color.init(cgColor: .init(gray: 0.9, alpha: 1)))
    }
        
    // --- 核心邏輯處理 ---
    
    // 初始化準備
    private func processDualPipeline(displayImage: UIImage, detectionImage: UIImage) {
        self.isShowDodge = false
        self.exposureCount = 0
        self.savedFaceRects = []
        self.pureOriginalImage = displayImage
        self.filteredImage = nil
        self.isFilterApplied = true
        self.originalImage = displayImage
        self.currentDisplayImage = displayImage
        self.statusDescription = "處理中..."
        
        Task {
            await self.processAutoPipeline(displayImage: displayImage, detectionImage: detectionImage)
        }
    }
    
    // 自動化管線
    private func processAutoPipeline(displayImage: UIImage, detectionImage: UIImage) async {
        await MainActor.run { self.isAnalyzing = true }
        
         //🎯 在管線中直接提取並印出
        if let hsb = await displayImage.getDominantColorHSB() {
            print("🔮 Pipeline 測試 -> H: \(hsb.hue), S: \(hsb.saturation), B: \(hsb.brightness)")

            // 在這裡做你的新版條件測試
            // 在接收時就把 hue, saturation, brightness 拆出來
            if let (hue, saturation, brightness) = await displayImage.getDominantColorHSB() {

                // 🎯 這樣你原本的這段程式碼就完全合法、不會報錯了！
                let isBrownish = (hue >= 0.0 && hue <= 0.15) &&
                                 (saturation >= 0.35) &&
                                 (brightness >= 0.15 && brightness <= 0.3)

                if isBrownish {
                    print("確認為棕色")
                }
            }
        }
        
        
        // 銳化偵測圖
        var finalDetectionImage = detectionImage
        if let cgImage = detectionImage.cgImage {
            let ciImage = CIImage(cgImage: cgImage)
            let sharpenFilter = CIFilter(name: "CISharpenLuminance")
            sharpenFilter?.setValue(ciImage, forKey: kCIInputImageKey)
            sharpenFilter?.setValue(0.6, forKey: kCIInputSharpnessKey)
            
            if let outputCIImage = sharpenFilter?.outputImage,
               let sharpenedCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) {
                finalDetectionImage = UIImage(cgImage: sharpenedCGImage, scale: detectionImage.scale, orientation: detectionImage.imageOrientation)
            }
        }
        
        detectionManager.detectFaces(in: finalDetectionImage, viewSize: nil) { count, rects in
            Task {
                // 🚀 關鍵：建立縮放後的座標陣列
                let scaleFactor: CGFloat = 2000.0 / 480.0
                let scaledRects = rects.map { rect in
                    CGRect(x: rect.minX * scaleFactor, y: rect.minY * scaleFactor,
                           width: rect.width * scaleFactor, height: rect.height * scaleFactor)
                }
                self.savedFaceRects = scaledRects // 儲存已經縮放過的座標
                let isDarkBrown = await detectionImage.checkIsDominantColorDarkBrown()
                var lutName = "gray_filter_lut"
                print("人臉數：\(count)")
                if isDarkBrown {
                    print("🎨 顏色判定結果：深咖啡色 ➔ 選擇濾鏡：\(lutName)")
                    lutName = (count > 4) ? "resto_people_filter_lut" : "food_filter_lut"
                    if (1...4).contains(count) {
                        await MainActor.run { self.isShowDodge = true }
                    }
                }
                
                // 修改處：明確使用 filteredResult (2000px) 進行補光計算
                if let filteredResult = self.filterManager.applyFilter(to: displayImage, lutName: lutName) {
                    var finalResult = filteredResult // 這裡的 filteredResult 是 2000px 的
                    if (1...4).contains(count)  && isDarkBrown {
                        if let dodgedImage = self.dodgeManager.applyFaceDodge(to: filteredResult, faceRects: scaledRects, count: self.exposureCount) {
                            finalResult = dodgedImage
                        }
                    }
                    
                    await MainActor.run {
                        self.isAnalyzing = false
                        self.filteredImage = filteredResult
                        self.statusDescription = "🎉 濾鏡：\(lutName)"
                        self.updateImageOutput()
                    }
                } else {
                    await MainActor.run { self.isAnalyzing = false; self.statusDescription = "❌ 失敗" }
                }
            }
        }
    }
    
    // 修改處：確保補光運算基於 baseImage (2000px)
    private func updateImageOutput() {
        let baseImage = isFilterApplied ? (filteredImage ?? pureOriginalImage ?? UIImage()) : (pureOriginalImage ?? UIImage())
        
        if exposureCount == 0 || !isShowDodge {
            currentDisplayImage = baseImage
            return
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            // 確保這裡傳入的 savedFaceRects 已經是縮放至 2000px 的數值
            if let renderedImage = self.dodgeManager.applyFaceDodge(to: baseImage, faceRects: self.savedFaceRects, count: self.exposureCount) {
                DispatchQueue.main.async { self.currentDisplayImage = renderedImage }
            }
        }
    }
}


#Preview {
    FilterAutoTest()
}
