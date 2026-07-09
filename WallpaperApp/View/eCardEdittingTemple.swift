//
//  Untitled 3.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/8.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins


enum ElementType {
    case text
    case sticker
    case photo
    case doodle
}

// 支援的濾鏡款式
enum FilterType: String, CaseIterable, Identifiable {
    case none = "原圖"
    case sepia = "懷舊"
    case mono = "黑白"
    case chrome = "冷調"
    case invert = "反相"
    
    var id: String { self.rawValue }
}

struct CanvasElement: Identifiable {
    var id = UUID()
    var type: ElementType
    var content: String // 文字內容 或 貼紙的 Asset 名稱 (無預設值，初始化必填)
    var position: CGPoint     // 在畫布上的中心點位置
    var rotation: Angle = .zero
    var scale: CGFloat = 1.0
    var color: Color = .black // 文字顏色 或 貼紙填色
    var fontName: String = "System"
    var isEditing: Bool = false // 🔴 新增：標記是否處於文字編輯狀態
    var istextAlignCenter: Bool = true
    
    // 照片屬性
    var rawImage: UIImage? = nil
    var filter: FilterType = .none
    
    // 塗鴉屬性
    var doodleStrokes: [[CGPoint]] = []
    var doodleSize: CGSize = .zero
    
    // 用於手勢的臨時狀態
    var lastScale: CGFloat = 1.0
    var lastRotation: Angle = .zero
}

// Core Image 濾鏡處理器
class FilterProcessor {
    static let shared = FilterProcessor()
    private let context = CIContext()
    
    func applyFilter(to image: UIImage, filterType: FilterType) -> UIImage {
        guard filterType != .none, let ciImage = CIImage(image: image) else { return image }
        
        var currentFilter: CIFilter?
        
        switch filterType {
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = ciImage
            filter.intensity = 0.8
            currentFilter = filter
        case .mono:
            let filter = CIFilter.photoEffectMono()
            filter.inputImage = ciImage
            currentFilter = filter
        case .chrome:
            let filter = CIFilter.photoEffectChrome()
            filter.inputImage = ciImage
            currentFilter = filter
        case .invert:
            let filter = CIFilter.colorInvert()
            filter.inputImage = ciImage
            currentFilter = filter
        case .none:
            return image
        }
        
        guard let outputImage = currentFilter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        // 🟢 修正：明確傳入原圖的 scale 與 imageOrientation，保留轉向標籤
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}


// 用於平滑渲染相對座標點的自訂幾何形狀
struct DoodleShape: Shape {
    var strokes: [[CGPoint]]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for stroke in strokes {
            guard stroke.count > 0 else { continue }
            
            // 如果只有一個點，畫一個小點
            if stroke.count == 1 {
                path.move(to: stroke[0])
                path.addEllipse(in: CGRect(x: stroke[0].x - 2, y: stroke[0].y - 2, width: 4, height: 4))
                continue
            }
            
            path.move(to: stroke[0])
            
            // 如果只有兩個點，直接連直線
            if stroke.count == 2 {
                path.addLine(to: stroke[1])
                continue
            }
            
            // 三個點以上，使用貝茲曲線進行平滑幾何轉換
            for i in 1..<stroke.count - 1 {
                let currentPoint = stroke[i]
                let nextPoint = stroke[i + 1]
                
                // 計算當前點與下一個點的中點，作為幾何路徑 ancher 的終點
                let midPoint = CGPoint(
                    x: (currentPoint.x + nextPoint.x) / 2,
                    y: (currentPoint.y + nextPoint.y) / 2
                )
                
                // 以當前點為控制點（Control Point），向中點繪製曲線
                path.addQuadCurve(to: midPoint, control: currentPoint)
            }
            
            // 連接最後一個點
            if let lastPoint = stroke.last {
                path.addLine(to: lastPoint)
            }
        }
        return path
    }
}


//----------------

struct StickerSheetView: View {
    @Binding var selectedColor: Color
    let stickerAssets: [String] // 存放所有 SVG 貼紙的名稱
    var onSelect: (String) -> Void
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .black, .white]
    
    var body: some View {
        VStack {
            // 上方顏色選擇器
            HStack {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 35, height: 35)
                        .overlay(Circle().stroke(Color.gray, lineWidth: selectedColor == color ? 2 : 0))
                        .onTapGesture {
                            selectedColor = color // 改變此值，下方所有使用此 Binding 的貼紙都會同步變色
                        }
                }
            }
            .padding()
            
            // 下方貼紙網格列表
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    ForEach(stickerAssets, id: \.self) { asset in
                        Image(asset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundStyle(selectedColor) // 關鍵：Template Image 會根據此處動態變色
                            .onTapGesture {
                                onSelect(asset)
                            }
                    }
                }
            }
        }
    }
}


//----------------------------


struct CanvasTextView: View {
    @Binding var element: CanvasElement
    @FocusState var isKeyboardFocused: Bool
    let fonts = ["Helvetica", "Courier", "Papyrus", "Georgia"]
//    @State private var istextAlignCenter: Bool = true
    private let baseFontSize: CGFloat = 24

    
    var body: some View {
        ZStack {
            if element.isEditing {
                // 🔥 編輯狀態：顯示輸入框，允許打字
                TextField("請輸入文字", text: $element.content, axis: .vertical)
                    .font(.custom(element.fontName, size: baseFontSize * element.scale))
                    .foregroundColor(element.color)
                    .focused($isKeyboardFocused)
                    .frame(maxWidth: 300, alignment: element.istextAlignCenter ? .center : .leading) // 限制固定寬度，讓文字滿了自動換行
                    .multilineTextAlignment(element.istextAlignCenter ? .center : .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .onAppear {
                        // 進入此狀態時，自動聚焦並彈出鍵盤
                        isKeyboardFocused = true
                    }
                    .onChange(of: isKeyboardFocused) { _, newValue in
                        // 當使用者主動收起鍵盤（失去焦點）時，自動關閉編輯狀態
                        if !newValue {
                            element.isEditing = false
                        }
                    }
                    .toolbar {
                        // 限制此工具列僅出現在鍵盤上方
                        ToolbarItemGroup(placement: .keyboard) {
                            // 1. 字型選擇器
                            Menu {
                                ForEach(fonts, id: \.self) { font in
                                    Button(font) {
                                        element.fontName = font
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("字型: \(element.fontName)")
                                    Image(systemName: "chevron.down")
                                }
                            }
                            
                            Button {
                                element.istextAlignCenter.toggle()
                            }label: {
                                Image(systemName: element.istextAlignCenter ? "text.alignleft" : "text.aligncenter")
                            }
                            
                            Spacer()
                            
                            // 2. 關閉鍵盤按鈕
                            Button(action: {
                                isKeyboardFocused = false // 解除焦點，鍵盤收起
                            }) {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
            }else {
                // 🔥 顯示狀態：使用純 Text，手勢不會被攔截，可自由移動
                Text(element.content.isEmpty ? "請輸入文字" : element.content)
                    .font(.custom(element.fontName, size: baseFontSize * element.scale))
                    .foregroundColor(element.color)
                    .lineLimit(nil)
                    .frame(maxWidth: 300, alignment: element.istextAlignCenter ? .center : .leading) // 保持與編輯狀態相同的固定寬度
                    .multilineTextAlignment(element.istextAlignCenter ? .center : .leading)
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
       
    }
}


//---------------------------

struct ShareItem: Identifiable {
    let id = UUID() // 確保每次生成的實例都有唯一的識別碼
    let image: UIImage
}

import PhotosUI
struct MainCanvasView: View {
    @State private var elements: [CanvasElement] = []
    @State private var selectedElementID: UUID? = nil
    @State private var selectedToColorChangeElementID: UUID? = nil
    @State private var showStickerSheet = false
    @State private var stickerGlobalColor = Color.black
    
    // 照片選擇器狀態
    @State private var selectedPickerItem: PhotosPickerItem? = nil
   
    
    // 塗鴉狀態控制
    @State private var isDrawingMode = false
    @State private var currentStroke: [CGPoint] = []          // 🟢 目前手指正拖動、尚未放開的單一筆跡
    @State private var sessionStrokes: [[CGPoint]] = []       // 🟢 這一輪塗鴉模式下，放開手指後累積的所有筆跡 (Undo 堆疊)
    @State private var redoStrokesHistory: [[CGPoint]] = [] // 🟢 存放被撤銷筆跡的歷史紀錄 (Redo 堆疊)
    @State private var selectedDoodleColor: Color = .black
    
    
    // 🟢 新增：用於控制是否正在導出圖片的狀態
    @State private var shareItem: ShareItem? = nil
    
    
    // Instagram Style 刪除邏輯狀態
    @State private var isDraggingElement = false
    @State private var draggingElementID: UUID? = nil
    @State private var dragLocation: CGPoint = .zero
    
    // 💡 用於記錄手勢開始時的初始位置，防止飛走
    @State private var basePosition: CGPoint = .zero

    // 刪除區域幾何資訊
    let canvasSize = CGSize(width: 360, height: 640)
    let trashZoneHeight: CGFloat = 80
    
    // 動態獲取未縮放時元件的原始基礎尺寸（用於計算相片約束邊界）
    private func elementBaseSize(for element: CanvasElement) -> CGSize {
        switch element.type {
        case .text:
            return CGSize(width: 300, height: 100)
        case .sticker:
            return CGSize(width: 80, height: 80)
        case .photo:
            if let uiImage = element.rawImage {
                let baseWidth: CGFloat = 200
                let aspectRatio = uiImage.size.height / uiImage.size.width
                let baseHeight = baseWidth * aspectRatio
                return CGSize(width: baseWidth + 50 , height: baseHeight + 40)
            }
            return CGSize(width: 220 , height: 220 )
        case .doodle:
            return element.doodleSize
        }
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack (alignment: .top) {
                // 畫布區域
                ZStack (alignment: .bottom) {
                    canvasBody(isExporting: false)
                        .frame(width: canvasSize.width, height: canvasSize.height)
                    
                    // Instagram 樣式：底部的刪除指示器（垃圾桶）
                    if isDraggingElement {
                        let isOverTrash = isPointInTrashZone(dragLocation)
                        
                        VStack {
                            Spacer()
                            Image(systemName: isOverTrash ? "trash.fill" : "trash")
                                .font(.system(size: 30))
                                .foregroundColor(isOverTrash ? .red : .gray)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.white.opacity(0.8)))
                                .scaleEffect(isOverTrash ? 1.2 : 1.0)
                                .padding(.bottom, 10)
                                .animation(.spring(), value: isOverTrash)
                        }
                        .frame(width: canvasSize.width, height: trashZoneHeight)
                        .transition(.move(edge: .bottom))
                    }
                }
                .clipped() // 確保內容不超出畫布
                
                // 下方功能操作列
                VStack {
                    Spacer()
                    bottomInspectorPanel
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            // 🟢 修正：升級為 iOS 17+ 雙參數 .onChange 語法，解決 image_db9160 / db9184 錯誤
                            PhotosPicker(selection: $selectedPickerItem, matching: .images) {
                                Text("照片")
                            }
                            .onChange(of: selectedPickerItem) { _, newItem in
                                if let newItem {
                                    Task {
                                        if let data = try? await newItem.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            await MainActor.run {
                                                // 尋找當前畫布內是否已存在相片元件
                                                if let photoIndex = elements.firstIndex(where: { $0.type == .photo }) {
                                                    // 💡 存在相片：直接更換內容（原位替換屬性），重置幾何至預設值
                                                    elements[photoIndex].rawImage = uiImage
                                                    selectedElementID = elements[photoIndex].id
                                                } else {
                                                    // 💡 不存在相片：新建唯一的相片元件
                                                    let newPhoto = CanvasElement(
                                                        type: .photo,
                                                        content: "",
                                                        position: CGPoint(x: 180, y: 320),
                                                        rawImage: uiImage
                                                    )
                                                    elements.append(newPhoto)
                                                    selectedElementID = newPhoto.id
                                                }
                                                selectedPickerItem = nil
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // 3. 塗鴉模式切換開關
                            Button(action: {
                                if isDrawingMode {
                                    // 🟢 核心修正：當關閉塗鴉狀態時，將之前畫的所有筆跡轉換成一個物件
                                    convertSessionToDoodleElement()
                                    isDrawingMode = false
                                } else {
                                    isDrawingMode = true
                                }
                            }) {
                                Label(isDrawingMode ? "結束塗鴉" : "手指塗鴉", systemImage: "pencil.line")
                                    .foregroundColor(isDrawingMode ? .white : .blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isDrawingMode ? Color.blue : Color.clear)
                                    .cornerRadius(8)
                            }
                            
                            
                            // 在 MainCanvasView 的「新增文字」按鈕動作中修改：
                            Button("文字") {
                                let newText = CanvasElement(
                                    type: .text,
                                    content: "請輸入文字",
                                    position: CGPoint(x: 180, y: 320),
                                    isEditing: true // 🔴 關鍵：一開始新增就是編輯狀態
                                )
                                elements.append(newText)
                                selectedElementID = newText.id
                            }
                            
                            Button("貼紙") {
                                showStickerSheet = true
                            }
                        }
                        .background(Color.white.opacity(0.5))
                    }
                }
                .padding(.horizontal)
                
                ForEach($elements) { $element in
                    let isSelected = selectedElementID == element.id
                    if element.type == .text, element.isEditing {
                        VStack{                            
                            Spacer()
                            CanvasTextView(element: $element)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea()
                        .background(Color.black.opacity(0.5))
                    }
                }
                
            }
            .sheet(isPresented: $showStickerSheet) {
                StickerSheetView(
                    selectedColor: $stickerGlobalColor,
                    stickerAssets: ["stick", "sticker_heart", "sticker_cat"], // 對應 Asset 內的 SVG 名稱
                    onSelect: { chosenAsset in
                        let newSticker = CanvasElement(
                            type: .sticker,
                            content: chosenAsset,
                            position: CGPoint(x: 200, y: 300),
                            color: stickerGlobalColor // 套用目前 Sheet 中選擇的顏色
                        )
                        elements.append(newSticker)
                        selectedElementID = newSticker.id
                        showStickerSheet = false
                    }
                )
                .presentationDetents([.medium, .large]) // 支援半開與全開 Sheet
            }
            // 🟢 修正：改用 .sheet(item:)。當 shareItem 不為 nil 時，Sheet 才會彈出
            // 並且內部閉包會直接拿到解包後的實例（此處的 item）
            .sheet(item: $shareItem) { item in
                ActivityViewController(activityItems: [item.image])
            }
            .toolbar {
                Button(action: {
                    // 🟢 觸發渲染與分享邏輯
                    renderAndShareCanvas()
                    
                }) {
                    Text("分享畫布")
                        .padding(10)
                        .background(.red)
                        .font(.headline)
                    
                }
            }
        }
    }
    // 🟢 將畫布本體抽離成獨立函數，以便重複調用（正常顯示 vs 導出渲染）
    private func canvasBody(isExporting: Bool) -> some View {
        ZStack {
            Color.init(cgColor: .init(gray: 0.85, alpha: 1))
                .onTapGesture {
                    selectedElementID = nil
                    selectedToColorChangeElementID = nil
                    // 若有文字正在編輯，收起鍵盤
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            ForEach($elements) { $element in
                let isSelected = !isExporting && selectedElementID == element.id
               
                Group {
                    switch element.type {
                    case .text:
                        if !element.isEditing {
                            CanvasTextView(element: $element)
                        }
                    case .sticker:
                        Image(element.content)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(element.color)
                    case .photo:
                        if let rawImage = element.rawImage {
                            Image(uiImage: FilterProcessor.shared.applyFilter(to: rawImage, filterType: element.filter))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200)
                                .padding(10)
                                .padding(.bottom, 20)
                                .background(Color.white)
                        }
                    case .doodle:
                        DoodleShape(strokes: element.doodleStrokes)
                            .stroke(
                                element.color,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: element.doodleSize.width, height: element.doodleSize.height)
                            .contentShape(Rectangle())
                    }
                }
                //💡關鍵修改：在縮放與旋轉之前，擴展物件周圍的手勢感應範圍（不要全局，只要周圍）
                .padding(40)
                .contentShape(Rectangle()) // 讓透明的 padding 區域也能觸發手勢
                .scaleEffect(element.type == .text ? 1.0 : element.scale)
                .rotationEffect(element.rotation)
                .position(element.position)
                // 🟢 移除所有外框線與按鈕，改採 Instagram Stories 純手勢操作
                .gesture(
                    isDrawingMode ? nil :
                    DragGesture()
                        .onChanged { value in
                            if !isDraggingElement {
                                isDraggingElement = true
                                draggingElementID = element.id
                                basePosition = element.position
                                selectedElementID = element.id
                                
                                if element.isEditing {
                                    element.isEditing = false
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }
                            
                            // 更新位置
                            element.position = CGPoint(
                                x: basePosition.x + value.translation.width,
                                y: basePosition.y + value.translation.height
                            )
                            
                            // 🔴 限制一：拖曳時若是相片，執行邊界與尺寸安全限幅限制，不可越界
                            if element.type == .photo {
                                clampPhotoGeometry(for: &element)
                            }
                            
                            dragLocation = value.location
                        }
                        .onEnded { _ in
                            if isPointInTrashZone(dragLocation) {
                                elements.removeAll { $0.id == draggingElementID }
                                selectedElementID = nil
                            }
                            isDraggingElement = false
                            draggingElementID = nil
                        }
                )
                .gesture(
                    isDrawingMode ? nil :
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                element.scale = element.lastScale * value
                                
                                // 🔴 限制二：縮放時若是相片，即時執行安全邊界截斷
                                if element.type == .photo {
                                    clampPhotoGeometry(for: &element)
                                }
                            }
                            .onEnded { _ in
                                element.lastScale = element.scale
                            },
                        RotationGesture()
                            .onChanged { value in
                                element.rotation = element.lastRotation + value
                                
                                // 🔴 限制三：旋轉時若是相片，即時重新計算外包圍框並卡死邊界
                                if element.type == .photo {
                                    clampPhotoGeometry(for: &element)
                                }
                            }
                            .onEnded { _ in
                                element.lastRotation = element.rotation
                            }
                    )
                )
                .onTapGesture(count: 1) {
                    if element.type == .text {
                        element.isEditing = true
                        //selectedElementID = element.id
                    }
                    selectedToColorChangeElementID = element.id
                }
            }
            
            // 塗鴉手勢攔截層
            if isDrawingMode {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                currentStroke.append(value.location)
                            }
                            .onEnded { _ in
                                if !currentStroke.isEmpty {
                                    sessionStrokes.append(currentStroke)
                                    currentStroke.removeAll()
                                    redoStrokesHistory.removeAll()
                                }
                            }
                    )
                
                DoodleShape(strokes: sessionStrokes + [currentStroke])
                    .stroke(
                        selectedDoodleColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .frame(width: 360, height: 640)
        .clipped()
    }
    
    // MARK: - 相片幾何限幅運算核心

    private func clampPhotoGeometry(for element: inout CanvasElement) {
        guard element.type == .photo else { return }
        
        let baseSize = elementBaseSize(for: element)
        let baseWidth = baseSize.width
        let baseHeight = baseSize.height
        
        let theta = element.rotation.radians
        let cosT = abs(cos(theta))
        let sinT = abs(sin(theta))
        
        // 計算矩形旋轉特定弧度 theta 後，投影在 X 軸與 Y 軸上的外擴最大半寬高
        let baseExtX = (baseWidth / 2) * cosT + (baseHeight / 2) * sinT
        let baseExtY = (baseWidth / 2) * sinT + (baseHeight / 2) * cosT
        
        // 依據畫布可視區 (360 x 640) 逆推當前角度下允許的最大縮放比率
        let maxScaleX = (canvasSize.width / 2) / baseExtX
        let maxScaleY = (canvasSize.height / 2) / baseExtY
        let maxAllowedScale = min(maxScaleX, maxScaleY)
        
        if element.scale > maxAllowedScale {
            element.scale = maxAllowedScale
        }
        if element.scale < 0.3 {
            element.scale = 0.3
        }
        
        // 算出最終確定縮放值後的外擴真實半寬高
        let extX = baseExtX * element.scale
        let extY = baseExtY * element.scale
        
        // 設定中心點 position 坐標的安全可移動邊界區間
        let minX = extX
        let maxX = canvasSize.width - extX
        let minY = extY
        let maxY = canvasSize.height - extY
        
        element.position.x = min(max(element.position.x, minX), maxX)
        element.position.y = min(max(element.position.y, minY), maxY)
    }
    
   
    
    // MARK: - 刪除區域判斷
    private func isPointInTrashZone(_ point: CGPoint) -> Bool {
        // 1. 定義垃圾桶判定區塊的寬高尺寸
        let trashWidth: CGFloat = 80
        let trashHeight: CGFloat = 80
        
        // 2. 計算 X 軸的中央安全範圍限制
        let canvasCenterX = canvasSize.width / 2
        let minX = canvasCenterX - (trashWidth / 2) // 180 - 40 = 140
        let maxX = canvasCenterX + (trashWidth / 2) // 180 + 40 = 220
        
        // 3. 計算 Y 軸的底部邊界限制
        let minY = canvasSize.height - trashHeight // 640 - 80 = 560
        
        // 4. 幾何依據：必須同時滿足在 X 軸中央範圍內，且在 Y 軸底部範圍內
        let isInXRange = point.x >= minX && point.x <= maxX
        let isInYRange = point.y >= minY
        
        return isInXRange && isInYRange
    }

    
    // 幾何座標轉換函數：將全螢幕軌跡打包為獨立邊界的元件
    private func convertSessionToDoodleElement() {
        // 若整個會話期都沒有畫任何筆跡，則不生成物件
        guard !sessionStrokes.isEmpty else { return }
        
        // 1. 攤平所有筆跡中的所有點，用以計算整體的邊界極值
        let allPoints = sessionStrokes.flatMap { $0 }
        let xs = allPoints.map { $0.x }
        let ys = allPoints.map { $0.y }
        
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return }
        
        // 2. 計算此多筆跡複合元件的實際 Frame 寬高
        let width = max(20, maxX - minX)
        let height = max(20, maxY - minY)
        
        // 3. 計算此複合型 Frame 的幾何中心點位置
        let centerPoint = CGPoint(x: minX + width / 2, y: minY + height / 2)
        
        // 4. 坐標歸一化：遍歷所有筆跡，將其內部的絕對坐標點全部減去左上角極值 (minX, minY)
        // 轉換為相對於該組件內部 Frame 的相對區域坐標
        let normalizedStrokes = sessionStrokes.map { stroke in
            stroke.map { pt in
                CGPoint(x: pt.x - minX, y: pt.y - minY)
            }
        }
        
        // 5. 建立單一的 CanvasElement 元件並存入陣列
        let newDoodle = CanvasElement(
            type: .doodle,
            content: "",
            position: centerPoint,
            color: selectedDoodleColor,
            doodleStrokes: normalizedStrokes,
            doodleSize: CGSize(width: width, height: height)
        )
        
        elements.append(newDoodle)
        selectedElementID = newDoodle.id
        
        // 6. 清空此輪塗鴉會話期的暫存資料與重做歷史
        sessionStrokes.removeAll()
        redoStrokesHistory.removeAll()
    }
    
    // 下方動態控制面板
    @ViewBuilder
    private var bottomInspectorPanel: some View {
        if isDrawingMode {
            // 塗鴉模式下：顯示顏色選擇器
            // 🟢 區塊 A：當處於塗鴉狀態時，在最上方獨立顯示「回上一動作」與「下一動作」控制列
            //if isDrawingMode {
                HStack(spacing: 20) {
                    Button(action: {
                        if let last = sessionStrokes.popLast() {
                            redoStrokesHistory.append(last)
                        }
                    }) {
                        Label("回上一動作", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(sessionStrokes.isEmpty)
                    
                    Button(action: {
                        if let next = redoStrokesHistory.popLast() {
                            sessionStrokes.append(next)
                        }
                    }) {
                        Label("下一動作", systemImage: "arrow.uturn.forward")
                    }
                    .disabled(redoStrokesHistory.isEmpty)
                }
                .font(.subheadline)
                .padding(.top, 4)
          //  }
            
            
            
            HStack {
                Text("塗鴉顏色：")
                ForEach([Color.black, Color.red, Color.blue, Color.green, Color.orange], id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.white, lineWidth: selectedDoodleColor == color ? 3 : 0))
                        .shadow(radius: 2)
                        .onTapGesture { selectedDoodleColor = color }
                }
            }
            .padding()
            .background(Color(.systemBackground))
        } else if let selectedID = selectedToColorChangeElementID,
                  let index = elements.firstIndex(where: { $0.id == selectedID }), !isDraggingElement {
            
            let element = elements[index]
            
            if element.type == .photo {
                // 照片元件選取時：顯示濾鏡切換面板
                VStack(alignment: .leading, spacing: 8) {
                    Text("相片濾鏡款式：").font(.caption).foregroundColor(.gray)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(FilterType.allCases) { fType in
                                Button(action: { elements[index].filter = fType }) {
                                    Text(fType.rawValue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(element.filter == fType ? Color.blue : Color(.quaternarySystemFill))
                                        .foregroundColor(element.filter == fType ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
            } else if element.type == .doodle {
                // 塗鴉元件選取時：允許事後更換物件顏色
                HStack {
                    Text("修改物件顏色：")
                    ForEach([Color.black, Color.red, Color.blue, Color.green, Color.orange], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.white, lineWidth: element.color == color ? 3 : 0))
                            .shadow(radius: 2)
                            .onTapGesture { elements[index].color = color }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }else if element.type == .sticker {
                // 塗鴉元件選取時：允許事後更換物件顏色
                HStack {
                    Text("修改貼紙顏色：")
                    ForEach([Color.black, Color.red, Color.blue, Color.green, Color.orange], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.white, lineWidth: element.color == color ? 3 : 0))
                            .shadow(radius: 2)
                            .onTapGesture { elements[index].color = color }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }else if element.type == .text {
                // 塗鴉元件選取時：允許事後更換物件顏色
                HStack {
                    Text("修改文字顏色：")
                    ForEach([Color.black, Color.red, Color.blue, Color.green, Color.orange], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.white, lineWidth: element.color == color ? 3 : 0))
                            .shadow(radius: 2)
                            .onTapGesture { elements[index].color = color }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            
        }
    }



    // 🟢 核心功能：視圖點陣化渲染函數
    @MainActor
    private func renderAndShareCanvas() {
        // 1. 建立一個完全乾淨、不帶任何 UI 控制控制項的虛擬畫布
        // 設定固定尺寸（例如 800x1000）以確保導出的圖片解析度不隨螢幕大小改變
        let exportView = canvasBody(isExporting: true)

        // 2. 使用 iOS 16 引入的 ImageRenderer 進行點陣化
        let renderer = ImageRenderer(content: exportView)
        
        // 3. 設定渲染縮放率（通常採用裝置的螢幕像素密度，如 @2x 或 @3x，確保圖片清晰不模糊）
        renderer.scale = 3

        // 4. 生成 UIImage 並觸發顯示分享選單
        if let uiImage = renderer.uiImage {
            // 🟢 修正：直接給 shareItem 賦值，SwiftUI 會保證資料寫入完成後才初始化 Sheet 視圖
            self.shareItem = ShareItem(image: uiImage)
        }
        
        
    }
}


#Preview {
    MainCanvasView()
}














struct CardEditorView: View {
     
    @State private var bodyText: String = "這是一段即時同步的祝福內文..."
    
    // 3. 字型狀態
    @State private var selectedFont: String = "System"
    let fontOptions = ["System", "FlaemischeKanzleischrift", "StarPandaKidsBeta2.1"]

    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.init(cgColor: .init(gray: 0.85, alpha: 1)).ignoresSafeArea()
                cardView
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 1, y: 6)
                
             
                    
                // 字型選擇器
                Picker("選擇字型", selection: $selectedFont) {
                    ForEach(fontOptions, id: \.self) { font in
                        Text(font == "System" ? "系統預設" : "手寫字體").tag(font)
                    }
                }
                .pickerStyle(.segmented)
               
                    
                
            }
            .toolbar {
                ShareLink(
                    item: exportModifiedImage(),
                    preview: SharePreview("專屬卡片分享", image: exportModifiedImage())
                ) {
                    Label("", systemImage: "square.and.arrow.up")
                    
                }
                .padding(.horizontal)
            }
        }
        
    }
    
    // --- 獨立抽離的視圖與邏輯 ---
    
    // 卡片本體視圖 (獨立抽離以供 ImageRenderer 渲染)
    private var cardView: some View {
        VStack(spacing: 16) {
            Image("myImageName")
                .resizable()
                .scaledToFit()
                .frame(width: 280)
                .clipped()
                .padding(.top, 10)
           
            // 內文編輯區 (即時同步)
            TextField("編輯內文 (即時更新)", text: $bodyText, axis: .vertical)
                .font(selectedFont == "System" ? .body : .custom(selectedFont, size: 18))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .padding()
        }
        .frame(width: 300)
        .background(Color.white)
    }
  
    // 將卡片視圖轉換為圖片 (iOS 26+ 現代標準)
    @MainActor
    private func exportModifiedImage() -> Image {
        let renderer = ImageRenderer(content: cardView)
        // 確保輸出的圖片解析度清晰
        renderer.scale = 3.0
        
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }
}


#Preview {
    CardEditorView()
}






