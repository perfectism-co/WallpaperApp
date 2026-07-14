//
//  Untitled 3.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/13.
//

import SwiftUI

// MARK: - 1. 物件資料模型
struct CanvasObject: Identifiable {
    let id = UUID()
    var text: String = "即時遮罩文字"
    
    // 位置與形變狀態
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var scale: CGFloat = 1.0
    var lastScale: CGFloat = 1.0
    var rotation: Angle = .zero
    var lastRotation: Angle = .zero
}

// MARK: - 2. 主視圖
struct MaskCanvasView: View {
    @State private var objects: [CanvasObject] = [
        CanvasObject(text: "單指拖曳測試"),
        CanvasObject(text: "雙指縮放旋轉")
    ]
    
    var body: some View {
        ZStack {
            // 背景底色
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            // ==========================================
            // 架構 A: 渲染層 (滿版底圖 + 遮罩)
            // ==========================================
            Image("gold") // 替換為您的圖片資產
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false) // 確保不攔截事件
                .mask(
                    ZStack {
                        Color.clear
                        ForEach(objects) { obj in
                            // 純渲染，不帶手勢
                            Text(obj.text)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.black)
                                .padding()
                                .rotationEffect(obj.rotation)
                                .scaleEffect(obj.scale)
                                .offset(obj.offset)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            
            // ==========================================
            // 架構 B: 互動層 (完全透明，專門接收手勢)
            // ==========================================
            ZStack {
                Color.clear // 保持容器透明
                
                ForEach($objects) { $obj in
                    InteractiveControlObject(object: $obj)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .coordinateSpace(name: "canvasSpace")
        }
    }
}

// MARK: - 3. 專責互動與手勢的透明組件
struct InteractiveControlObject: View {
    @Binding var object: CanvasObject
    
    var body: some View {
        // 使用 contentShape 確保整塊區域（包含 padding 與文字間隙）都能點擊到
        Text(object.text)
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(.clear) // 【關鍵】互動層物件必須是透明的
            .padding()
            .contentShape(Rectangle()) // 擴展觸控熱區
            .rotationEffect(object.rotation)
            .scaleEffect(object.scale)
            .offset(object.offset)
            .gesture(
                DragGesture(coordinateSpace: .named("canvasSpace"))
                    .onChanged { value in
                        object.offset = CGSize(
                            width: object.lastOffset.width + value.translation.width,
                            height: object.lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        object.lastOffset = object.offset
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        object.scale = object.lastScale * value
                    }
                    .onEnded { _ in
                        object.lastScale = object.scale
                    }
            )
            .simultaneousGesture(
                RotationGesture()
                    .onChanged { value in
                        object.rotation = object.lastRotation + value
                    }
                    .onEnded { _ in
                        object.lastRotation = object.rotation
                    }
            )
    }
}


// MARK: - Preview
#Preview {
    MaskCanvasView()
}
