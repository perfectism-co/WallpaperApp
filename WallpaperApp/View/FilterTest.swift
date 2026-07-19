import SwiftUI
import PhotosUI

struct FilterTest: View {
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    
    // 實例化濾鏡管理器
    let filterManager = LUTFilterManager()

    var body: some View {
        ScrollView { // 使用 ScrollView 包裹，確保排版正常且不重疊
            VStack(spacing: 25) {
                
                Text("濾鏡效果測試")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                
                // 1. 影像顯示區
                // 優先顯示「套用濾鏡後」的圖片，如果沒有，則顯示「原始選取」的圖片
                if let imageToDisplay = processedImage ?? selectedImage {
                    Image(uiImage: imageToDisplay)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 350)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                } else {
                    // 未選取照片時的預設灰色框
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 350)
                        .overlay(
                            VStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("尚未選取照片")
                                    .foregroundColor(.gray)
                            }
                        )
                        .padding(.horizontal)
                }
                
                // 2. 選擇照片按鈕
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("選擇照片")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        // 確保異步下載完成後回到主線程更新 UI
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                self.selectedImage = image
                                self.processedImage = nil // 選擇新照片時，清除前一張的濾鏡結果
                                print("✅ 成功載入新照片，尺寸：\(image.size)")
                            }
                        } else {
                            await MainActor.run {
                                print("❌ 影像資料載入失敗（請確認選取的相片格式是否支援）")
                            }
                        }
                    }
                }
                
                // 3. 套用濾鏡按鈕
                HStack {
                    Button(action: {
                        // 檢查原始照片是否存在
                        guard let original = selectedImage else {
                            print("⚠️ 失敗：尚未選取照片，無法套用濾鏡")
                            return
                        }
                        
                        print("👉 開始嘗試套用濾鏡...")
                        
                        // 執行濾鏡
                        if let result = filterManager.applyFilter(to: original, lutName: "resto_people_filter_lut") {
                            self.processedImage = result
                            print("🎉 濾鏡套用成功！(fitted)")
                        } else {
                            print("❌ 濾鏡套用失敗：請確認 'resto_people_filter_lut.png' 是否已成功加入專案目錄（Bundle），且 Target Membership 有勾選。")
                        }
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("餐廳")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        // 依據是否有照片動態改變顏色，提示使用者按鈕狀態
                        .background(selectedImage == nil ? Color.gray : Color.orange)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(selectedImage == nil)// 如果沒選照片，禁用按鈕
                    
                    
                    Button(action: {
                        // 檢查原始照片是否存在
                        guard let original = selectedImage else {
                            print("⚠️ 失敗：尚未選取照片，無法套用濾鏡")
                            return
                        }
                        
                        print("👉 開始嘗試套用濾鏡...")
                        
                        // 執行濾鏡
                        if let result = filterManager.applyFilter(to: original, lutName: "food_filter_lut") {
                            self.processedImage = result
                            print("🎉 濾鏡套用成功！(fitted)")
                        } else {
                            print("❌ 濾鏡套用失敗：請確認 'food_filter_lut.png' 是否已成功加入專案目錄（Bundle），且 Target Membership 有勾選。")
                        }
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("食物")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        // 依據是否有照片動態改變顏色，提示使用者按鈕狀態
                        .background(selectedImage == nil ? Color.gray : Color.orange)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(selectedImage == nil) // 如果沒選照片，禁用按鈕
                    
                    
                    Button(action: {
                        // 檢查原始照片是否存在
                        guard let original = selectedImage else {
                            print("⚠️ 失敗：尚未選取照片，無法套用濾鏡")
                            return
                        }
                        
                        print("👉 開始嘗試套用濾鏡...")
                        
                        // 執行濾鏡
                        if let result = filterManager.applyFilter(to: original, lutName: "gray_filter_lut") {
                            self.processedImage = result
                            print("🎉 濾鏡套用成功！(fitted)")
                        } else {
                            print("❌ 濾鏡套用失敗：請確認 'gray_filter_lut.png' 是否已成功加入專案目錄（Bundle），且 Target Membership 有勾選。")
                        }
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("灰調")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        // 依據是否有照片動態改變顏色，提示使用者按鈕狀態
                        .background(selectedImage == nil ? Color.gray : Color.orange)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(selectedImage == nil) // 如果沒選照片，禁用按鈕
                    
                    
                }
                
                
                
                // 4. 還原按鈕（僅在有套用濾鏡時顯示）
                if processedImage != nil {
                    Button("還原原始相片") {
                        self.processedImage = nil
                    }
                    .foregroundColor(.red)
                    .font(.subheadline)
                }
            }
        }
    }
}

#Preview {
    FilterTest()
}
