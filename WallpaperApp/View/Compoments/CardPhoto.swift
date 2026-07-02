//
//  CardPhoto.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/30.
//

import SwiftUI
import PhotosUI

struct CardPhoto: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showDialog = false
    @State private var showPicker = false // 新增一個狀態來控制 Picker

    var body: some View {
        VStack(spacing: 20) {
            // 顯示圖片區域
            Button {
                showDialog = true
            } label: {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipped()
                } else {
                    Image("myImageName")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipped()
                }
            }
            .buttonStyle(.plain) // 確保點擊後不會有原本 Button 的淡入淡出效果
            .confirmationDialog("Choose Photo Type", isPresented: $showDialog, titleVisibility: .visible) {
                Button("當前手機桌布") {
                    selectedImage = nil
                }
                    
                // 這裡改成普通按鈕，點擊後觸發 showPicker
                Button("上傳照片") {
                    showPicker = true
                }
                
            } message: {
                Text("請選擇來源")
            }
            // 將 PhotosPicker 移出對話框，設為隱藏或透過觸發條件顯示
            .photosPicker(isPresented: $showPicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    CardPhoto()
}
