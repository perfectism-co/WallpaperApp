//
//  PhotoUploadView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/30.
//

import SwiftUI
import PhotosUI

struct PhotoUploadView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            // 顯示選取的圖片
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(Text("尚未選取照片"))
            }

            // 選取按鈕
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text("選擇照片")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    // 載入影像資料
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        // 在此處呼叫上傳功能
                        uploadImage(data: data)
                    }
                }
            }
        }
        .padding()
    }

    // 上傳邏輯函數
    func uploadImage(data: Data) {
        let url = URL(string: "https://your-api-endpoint.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 此處實作 multipart/form-data 的組裝 (同前一則回覆)
        // ... (省略重複的 body 組裝邏輯) ...
        
        URLSession.shared.uploadTask(with: request, from: data).resume()
    }
}

#Preview {
    PhotoUploadView()
}
