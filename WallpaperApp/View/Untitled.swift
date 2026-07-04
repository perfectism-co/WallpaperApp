//
//  Untitled.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/3.
//

import SwiftUI

struct KeyboardSubmitView: View {
    // 💡 1. 雙狀態分離邏輯
    @State private var typingText: String = ""      // 負責打字時的暫存
    @State private var submittedText: String = ""   // 負責真正顯示在畫面上的內容
    
    // 💡 2. 宣告式焦點控制（用來控制鍵盤彈起與收起）
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                // 畫面主體只依賴 submittedText
                Text(submittedText.isEmpty ? "請在下方輸入內容..." : submittedText)
                    .font(.title)
                    .padding()
                Button ("open"){
                    isInputFocused = true
                }
                Spacer()
            }
            .navigationTitle("eCard 輸入示範")
            // 點擊畫面空白處，強制收起鍵盤
            .onTapGesture {
                isInputFocused = false
            }
            // 💡 3. 現代鍵盤工具列佈局
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack(spacing: 12) {
                        TextField("請輸入內容...", text: $typingText)
                            .textFieldStyle(.roundedBorder)
                            .focused($isInputFocused) // 綁定焦點
                            .submitLabel(.send)       // 將原生鍵盤右下角按鈕改為「送出」
                        
                        // 自訂的送出按鈕
                        Button {
                            sendContent()
                        } label: {
                            Text("送出")
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        // 防呆機制：如果只有空白或是沒打字，按鈕反灰
                        .disabled(typingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 4)
                }
            }
            // 💡 4. 監聽原生鍵盤右下角的「送出」按鈕
            .onSubmit(of: .text) {
                sendContent()
            }
        }
    }
    
    // 獨立的送出邏輯處理
    private func sendContent() {
        let trimmedText = typingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            // 只有在這時候，才把暫存字串同步到頁面上，觸發畫面重繪
            submittedText = trimmedText
            
            // 清空輸入框暫存
            typingText = ""
            
            // 將焦點設為 false，鍵盤就會平滑地下滑收起
            isInputFocused = false
        }
    }
}

#Preview {
    KeyboardSubmitView()
}
