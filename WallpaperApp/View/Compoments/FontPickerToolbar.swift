//
//  FontPickerToolbar.swift
//  WallpaperApp
//

import SwiftUI

struct FontPickerToolbar: View {
    @Binding var selectedFont: CustomFontOption        // 內文
    @Binding var selectedTitleFont: CustomFontOption   // 標題
    @Binding var selectedTapeColor: TapeColorOption
    @Binding var selectedCard: CardType
    @State private var isFold: Bool = true
    
    var isTitleFocused: Bool
    
    let tapeColors: [TapeColorOption] = [
        TapeColorOption(name: "deep-red-tape", hex: "#7d1a1a"),
        TapeColorOption(name: "deep-orange-tape", hex: "#f69240"),
        TapeColorOption(name: "deep-yellow-tape", hex: "#ffbb00"),
        TapeColorOption(name: "deep-green-tape", hex: "#284823"),
        TapeColorOption(name: "deep-pink-tape", hex: "#e6589b"),
        TapeColorOption(name: "morandi-skin-tape", hex: "#f6e4bf"),
        TapeColorOption(name: "morandi-pink-tape", hex: "#eac4d2"),
        TapeColorOption(name: "morandi-purple-tape", hex: "#d5cbec"),
        TapeColorOption(name: "morandi-blue-tape", hex: "#bed9e8"),
        TapeColorOption(name: "morandi-green-tape", hex: "#c0dbb4")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if selectedCard == CardType.eCardVer2 && isTitleFocused {
                if isFold {
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                Text("Tape Color")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                ForEach(tapeColors, id: \.self) { option in
                                    Circle()
                                        .fill(option.color) // 使用計算屬性轉換出的 Color
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: selectedTapeColor == option ? 2 : 0)
                                                .padding(-4)
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring) {
                                                selectedTapeColor = option // 儲存整個物件
                                            }
                                        }
                                }
                            }
                        }
                        Spacer()
                        Button {
                            withAnimation(.spring) { isFold = false }
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .foregroundStyle(Color.init(uiColor: .label))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(uiColor: .tertiarySystemBackground))
                } else{
                    VStack {
                        Button {
                            withAnimation(.spring) { isFold = true }
                        } label: {
                            Image(systemName: "chevron.down")
                                .padding(8)
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.top, 8)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 16) {
                                ForEach(tapeColors, id: \.self) { option in
                                    HStack {
                                        // 顯示顏色預覽與名稱
                                        Image("stick")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 40)
                                            .foregroundStyle(option.color)
                                        
                                        Text(option.name)
                                            .font(.footnote)
                                            .foregroundColor(selectedTapeColor == option ? .primary : .secondary)
                                        
                                        Spacer()
                                        
                                        Text(option.hex)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .opacity(selectedTapeColor == option ? 1.0 : 0.4)
                                    .contentShape(Rectangle()) // 擴大點擊有效區域
                                    .onTapGesture {
                                        withAnimation(.spring) {
                                            selectedTapeColor = option
                                        }
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .background(Color(uiColor: .tertiarySystemBackground))
                }
                
            }
            
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(currentOptions) { option in  // ← 改用 currentOptions
                        Button {
                            if isTitleFocused {
                                selectedTitleFont = option
                            } else {
                                selectedFont = option
                            }
                        } label: {
                            Text(option.displayName)
                                .font(option.displayFont)
                                .foregroundStyle(currentFont == option ? Color(uiColor: .darkText) : Color(uiColor: .label))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    currentFont == option ? Color.white : .white.opacity(0.15)
                                )
                                .clipShape(Capsule())
                        }
                        .sensoryFeedback(.selection, trigger: currentFont)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color(uiColor: .secondarySystemBackground))
        }
    }
    
    // MARK: - Helper
    private var currentFont: CustomFontOption {
        isTitleFocused ? selectedTitleFont : selectedFont
    }
    
    private var currentOptions: [CustomFontOption] {
        isTitleFocused ? FontManager.shared.titleFontOptions : FontManager.shared.bodyFontOptions
    }
}

