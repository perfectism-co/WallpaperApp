//
//  CardDesign.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/28.
//

import SwiftUI

struct SnapshotCard1: View {
    let cardTitle: String
    let cardBodyText: String
    let selectedFont: CustomFontOption
    let selectedTitleFont: CustomFontOption
    let uiImage: UIImage?
    let dominantColor: Color
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .top) {
                Image(uiImage: uiImage!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .clipped()
                
                // 顏色漸層遮罩
                ZStack(alignment: .bottom) {
                    Color.clear.frame(width: 300, height: 300)
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [dominantColor.opacity(0), dominantColor.opacity(1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                }
                
                // 文字
                VStack(spacing: 0) {
                    Color.clear.frame(width: 300, height: 250)
                    
                    Text(cardTitle)
                        .font(selectedTitleFont.targetFont(48))
                        .lineLimit(1...3)
                        .padding()
                        .padding(.bottom, 48)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white)
                
                    if !cardBodyText.isEmpty {
                        Text(cardBodyText)
                            .font(selectedFont.targetFont(18))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 26)
                            .padding(.vertical)
                            
                    }
                }
                .padding(.bottom, 50)
            }
            
            
            // Watermark
            HStack {
                Spacer()
                Image("QRCord")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15)
                    .foregroundStyle(Color.white)
            }
            .padding(4)
        }
        .background(dominantColor)
        .frame(width: 300)
        //.clipShape(RoundedRectangle(cornerRadius: 4))
    }
}


#Preview {
    SnapshotCard1( cardTitle: "Happy Birthday", cardBodyText: "123", selectedFont: FontManager.shared.defaultBodyFont, selectedTitleFont: FontManager.shared.defaultTitleFont, uiImage: UIImage(named: "myImageName"), dominantColor: Color.blue)
}


//MARK: - CardVer2


struct SnapshotCard2: View {
    let cardTitle: String
    let cardBodyText: String
    let selectedFont: CustomFontOption
    var selectedTitleFont: CustomFontOption
    let uiImage: UIImage?
   
    let dominantColor: Color
    let selectedTapeColor: TapeColorOption
    let textHeight: CGFloat
    
  
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .top) {
                Image(uiImage: uiImage!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .clipped()
                
                
                VStack(spacing: 35) {
                    // 膠帶與標題
                    ZStack {
                        Image(selectedTapeColor.name)
                            .resizable()
                            .frame(maxWidth: .infinity)
                            .frame(height: textHeight)
                        
                        Text(cardTitle)
                            .font(selectedTitleFont.targetFont(48))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.black.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    
                    // 內文
                    if !cardBodyText.isEmpty {
                        Text(cardBodyText)
                            .font(selectedFont.targetFont(18))
                            .foregroundStyle(Color.black.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 26)
                    }
                }
                .alignmentGuide(.top) { d in d[.top] - 294 }
                .padding(.bottom, 50)
            }
            
            // Watermark
            HStack {
                Spacer()
                Image("QRCord")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15)
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            .padding(4)
            
        }
        .frame(width: 300)
        .background(.white)
        .compositingGroup()
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}


#Preview {
    SnapshotCard2( cardTitle: "生日快樂Happy", cardBodyText: "1456", selectedFont: FontManager.shared.defaultBodyFont, selectedTitleFont: FontManager.shared.titleFontOptions[1], uiImage: UIImage(named: "myImageName"), dominantColor: Color.brown, selectedTapeColor: TapeColorOption(name: "deep-yellow-tape", hex: "#FFCC00"), textHeight: 50) // 傳入預覽高度[cite: 6]
}
