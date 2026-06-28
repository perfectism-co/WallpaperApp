//
//  FontPickerToolbar.swift
//  WallpaperApp
//

import SwiftUI

struct FontPickerToolbar: View {
    @Binding var selectedFont: CustomFontOption        // 內文字型
    @Binding var selectedTitleFont: CustomFontOption   // 標題字型
    
    let fontOptions: [CustomFontOption]
    
    // 新增：目前正在編輯哪一個欄位
    var isTitleFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(fontOptions) { option in
                        Button {
                            if isTitleFocused {
                                selectedTitleFont = option
                            } else {
                                selectedFont = option
                            }
                        } label: {
                            Text(option.displayName)
                                .font(option.displayFont)
                                .foregroundColor(currentFont == option ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    currentFont == option ? Color.white : Color.white.opacity(0.15)
                                )
                                .clipShape(Capsule())
                        }
                        .sensoryFeedback(.selection, trigger: currentFont)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .glassEffect()
        }
    }
    
    private var currentFont: CustomFontOption {
        isTitleFocused ? selectedTitleFont : selectedFont
    }
}
