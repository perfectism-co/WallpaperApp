//
//  tset.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/7.
//

import SwiftUI
import PhotosUI
import Combine


// MARK: - Model (資料模型)
struct TodoItem: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var image: UIImage?
}

// MARK: - ViewModel (視圖模型)
@MainActor // 確保所有資料更新都在主執行緒執行
class TodoViewModel: ObservableObject {
    @Published var items: [TodoItem] = []
    
    /// 新增一筆空白的文字待辦事項
    func addTextItem() {
        items.append(TodoItem(text: "", image: nil))
    }
    
    /// 新增一筆帶有圖片的待辦事項
    func addImageItem(image: UIImage) {
        items.append(TodoItem(text: "", image: image))
    }
    
    /// 處理陣列資料的移動邏輯，對應 UI 的拖曳排序
    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
    
    /// 處理刪除邏輯：根據 UI 傳回的索引集合（IndexSet）移除陣列中的對應資料
    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

// MARK: - View (主畫面)
struct ContentView: View {
    @StateObject private var viewModel = TodoViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground) // 這裡的背景色代表你 App 的底色
                    .ignoresSafeArea()
                List {
                    // 必須使用 ForEach 搭配 Binding 陣列 ($viewModel.items)
                    // 才能啟用直接編輯與排序功能
                    ForEach($viewModel.items) { $item in
                        HStack {
                            // 圖片區塊：若該項目包含圖片則顯示
                            if let image = item.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 300, height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }else{
                                // 文字區塊：直接在列表內部綁定 TextField 提供直接輸入
                                TextField("請輸入待辦內容", text: $item.text)
                                    .textFieldStyle(.plain)
                            }
                            
                        }
                        .listRowSeparator(.hidden)       // 隱藏行與行之間的分割線 (框線)
                        .listRowBackground(Color.clear)  // 將每一行的獨立背景設為透明
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) // 調整間距，避免文字貼邊
                    }
                    // 加入 onMove 修飾符，系統會自動在 iOS 16+ 啟用長按項目進行拖曳排序的功能
                    .onMove(perform: viewModel.moveItem)
                    .onDelete(perform: viewModel.deleteItem)
                }
                .listStyle(.plain)                  // 設定為 plain 樣式，移除內建的分組邊框與間距
                .scrollContentBackground(.hidden)   // iOS 16+ 核心：隱藏 List 容器自帶的預設灰色背景
            }
           
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        
                        // 1. 新增文字按鈕：點擊後在陣列末端加入空字串項目
                        Button(action: {
                            viewModel.addTextItem()
                        }) {
                            Image(systemName: "text.badge.plus")
                        }
                        
                        // 2. 新增圖片按鈕：直接呼叫相簿
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Image(systemName: "photo.badge.plus")
                        }
                        // 監聽照片選擇結果
                        .onChange(of: selectedPhotoItem) { oldValue, newValue in
                            Task {
                                // 將原本的 newItem 替換為 newValue
                                if let data = try? await newValue?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    await MainActor.run {
                                        viewModel.addImageItem(image: uiImage)
                                    }
                                }
                                selectedPhotoItem = nil
                            }
                        }
                        
                        // 一鍵分享按鈕：每次點擊分享選單彈出時，ShareLink 會動態觸發這個 Image
//                       ShareLink(
//                           item: exportModifiedImage, // 這裡已經是非 Optional 的 Image 了
//                           preview: SharePreview("自製桌布", image: exportModifiedImage)
//                       ) {
//                           Label("Share Your eCard", systemImage: "square.and.arrow.up")
//                               .foregroundStyle(Color.init(uiColor: .label))
//                               .padding()
//                               
//                       }
                    }
                }
            }
        }
    }
    
    @MainActor // 💡 UI 渲染必須在主執行緒進行
    func exportModifiedImage() -> UIImage? {
        // 1. 將剛剛設計好的 SwiftUI View 放進渲染器
        let renderer = ImageRenderer(content: ContentView())
        
        // 2. (重要) 確保輸出圖片的解析度與目前設備螢幕比例一致，才不會模糊
        // 💡 2. 替換為環境變數，完美適配多螢幕與高解析度設備
        renderer.scale = 3
        
        // 3. 輸出並傳出最終的 UIImage
        return renderer.uiImage
    }
}


#Preview {
    ContentView()
}
