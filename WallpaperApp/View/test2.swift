//
//  test2.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/24.
//

import SwiftUI



struct LiveMaskView: View {
    // 儲存塗鴉的所有點
    @State private var currentPoints: [CGPoint] = []
    // 儲存輸入的文字
    @State private var inputText: String = ""
    
    var body: some View {
        ZStack {
            // 1. 滿版底圖
            Image("myImageName")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                // 2. 使用 .mask 修飾符，裡面放入我們想要顯現的形狀與文字
                .mask(
                    ZStack {
                        // 塗鴉路徑：有線條的地方才會顯示底圖
                        Path { path in
                            guard let first = currentPoints.first else { return }
                            path.move(to: first)
                            for point in currentPoints.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                        .stroke(Color.black, style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        
                        // 文字：輸入什麼，那個位置就會顯現底圖
                        Text(inputText)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.black)
                            .position(x: 200, y: 300)
                    }
                )
            
            // 3. 接收手勢與文字輸入的控制層
            VStack {
                TextField("正在輸入時即時顯示遮罩...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Spacer()
            }
            // 畫筆手勢：每次移動即時更新狀態，SwiftUI 會自動、高效地重新渲染 mask
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentPoints.append(value.location)
                    }
            )
        }
    }
}

#Preview {
    LiveMaskView()
}












struct test2: View {
    @State private var isBarHidden = false
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(0..<30) { i in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.15))
                                .frame(height: 250)
                                .overlay(Text("桌布預覽 \(i)"))
                                .padding(.horizontal)
                        }
                    }
                }
                .navigationTitle("選擇桌布")
                .navigationBarTitleDisplayMode(.inline) // 固定小標題
                
                // 💡 iOS 18 新增的滾動幾何偵測
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y // 抓取 y 軸滾動距離
                } action: { oldValue, newValue in
                    // newValue > oldValue 代表頁面正在「往下滑動」（內容往上跑）
                    if newValue > 100 && newValue > oldValue {
                        if !isBarHidden {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isBarHidden = true
                            }
                        }
                    } else if newValue < oldValue {
                        // 往上滑動（內容往下跑）時，重新顯示導覽列
                        if isBarHidden {
                            withAnimation(.easeIn(duration: 0.2)) {
                                isBarHidden = false
                            }
                        }
                    }
                }
                // 動態切換隱藏或顯示
                .toolbar(isBarHidden ? .hidden : .visible, for: .navigationBar)
            }
        }
}

#Preview {
    test2()
}
