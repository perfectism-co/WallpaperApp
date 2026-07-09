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

// 用於渲染相對座標點的自訂幾何形狀
struct DoodleShape: Shape {
    // 🟢 修正：接收多條筆跡並逐一繪製路徑
    var strokes: [[CGPoint]]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for stroke in strokes {
            guard let firstPoint = stroke.first else { continue }
            path.move(to: firstPoint)
            for point in stroke.dropFirst() {
                path.addLine(to: point)
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

//struct ElementWrapperView<Content: View>: View {
//    @Binding var element: CanvasElement
//    var isSelected: Bool
//    var isDrawingMode: Bool
//    var onDelete: () -> Void
//    var content: Content
//    
//    
//    // 💡 用於記錄手勢開始時的初始狀態，防止數值連續疊加導致元件飛走
//    @State private var basePosition: CGPoint = .zero
//    @State private var isDragging: Bool = false
//    
//   
//    
//    init(
//        @ViewBuilder content: () -> Content,
//        element: Binding<CanvasElement>,
//        isSelected: Bool,
//        isDrawingMode: Bool,
//        onDelete: @escaping () -> Void
//    ) {
//        self.content = content()
//        self._element = element
//        self.isSelected = isSelected
//        self.isDrawingMode = isDrawingMode // 🟢 賦值
//        self.onDelete = onDelete
//    }
//    
//    
//    // 💡 幾何依據：依據元件型別，動態計算或讀取未經縮放時的「真實基礎尺寸」
//    private var elementBaseSize: CGSize {
//        switch element.type {
//        case .text:
//            // 文字寬度在視圖中固定為 300，高度給定合理的預設估計值 100
//            return CGSize(width: 300, height: 100)
//        case .sticker:
//            // 貼紙尺寸固定為 80 x 80
//            return CGSize(width: 80, height: 80)
//        case .photo:
//            if let uiImage = element.rawImage {
//                let baseWidth: CGFloat = 200
//                let aspectRatio = uiImage.size.height / uiImage.size.width
//                let baseHeight = baseWidth * aspectRatio
//                // 依據相片規格計算：寬度增加左右 padding (10 + 10) = 220
//                // 高度增加上下 padding (10 + 10) 與底部額外 padding 20 = baseHeight + 40
//                return CGSize(width: baseWidth + 50, height: baseHeight + 40)
//            }
//            return CGSize(width: 220, height: 220)
//        case .doodle:
//            // 塗鴉直接採用 convertPointsToDoodleElement() 算出的精準 doodleSize
//            return element.doodleSize
//        }
//    }
//    
//    var body: some View {
//        content
//            .frame(minWidth: 50, minHeight: 50)
//            .scaleEffect(element.scale)
//            .rotationEffect(element.rotation)
////            .overlay(
////                // 邊框線
////                Rectangle()
////                    .stroke(
////                        (isSelected && !isDrawingMode) ? Color.gray : .clear,
////                        style: StrokeStyle(
////                            lineWidth: 1,
////                            dash: [5, 3] // 5 點長度的實線，3 點長度的空白
////                        )
////                    )
////                    .scaleEffect(element.scale)
////                    .rotationEffect(element.rotation)
////            )
//            .position(element.position)
////            .gesture(
////                // 🟢 修正四：若正在編輯文字或處於塗鴉模式，則停用拖動手勢，避免手勢衝突
////                (element.isEditing || isDrawingMode) ? nil : DragGesture()
////                    .onChanged { value in
////                        element.position = value.location
////                    }
////            )
//            .gesture(
//                (element.isEditing || isDrawingMode) ? nil :
//                DragGesture()
//                    .onChanged { value in
//                        // 當手指點下剛觸發時，鎖定當前的絕對座標作為基準值
//                        if !isDragging {
//                            isDragging = true
//                            basePosition = element.position
//                        }
//                        
//                        // 透過基準值加上手指移動的絕對位移量（translation）來更新坐標
//                        element.position = CGPoint(
//                            x: basePosition.x + value.translation.width,
//                            y: basePosition.y + value.translation.height
//                        )
//                        
//                        // 🔴 限制一：若是相片，即時執行邊界與尺寸限制，不可超出 360 x 640
//                        if element.type == .photo {
//                            clampPhotoGeometry()
//                        }
//                    }
//                    .onEnded { _ in
//                        isDragging = false // 手勢結束，釋放鎖定
//                    }
//            )
//            
////            .overlay(
////                Group {
////                    if isSelected && !isDrawingMode {
////                        // 右上方：刪除按鈕
////                        Button(action: { onDelete() }) {
////                            Image(systemName: "xmark.circle.fill")
////                                .foregroundColor(.red)
////                                .background(Circle().fill(Color.white))
////                        }
////                        .offset(x: (elementBaseSize.width / 2) * element.scale,
////                                                        y: -(elementBaseSize.height / 2) * element.scale)
////                        //.offset(x: 40 * element.scale, y: -40 * element.scale) // 需根據縮放計算偏移量
////                        .rotationEffect(element.rotation)
////                        .position(element.position)
////                        
////                        // 🔴 新增：左上方：編輯按鈕（僅在文字元件且非編輯狀態時顯示）
////                        if element.type == .text && !element.isEditing {
////                            Button(action: {
////                                element.isEditing = true // 點擊切換為編輯狀態
////                            }) {
////                                Image(systemName: "pencil.circle.fill")
////                                    .foregroundColor(.accentColor)
////                                    .background(Circle().fill(Color.white))
////                            }
////                            .offset(x: -(elementBaseSize.width / 2) * element.scale,
////                                                                y: -(elementBaseSize.height / 2) * element.scale)
////                            //.offset(x: -40 * element.scale, y: -40 * element.scale) // 左上方偏移
////                            .rotationEffect(element.rotation)
////                            .position(element.position)
////                        }
////                        
////                        // 右下角：旋轉 + 縮放控制鈕
//////                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
//////                            .foregroundColor(.blue)
//////                            .background(Circle().fill(Color.white))
//////                            .offset(x: 40 * element.scale, y: 40 * element.scale)
//////                            .rotationEffect(element.rotation)
//////                            .position(element.position)
//////                            .gesture(
//////                                DragGesture()
//////                                    .onChanged { value in
//////                                        let center = element.position
//////                                        let touchPoint = value.location
//////                                        
//////                                        // 1. 計算旋轉角度
//////                                        let radians = atan2(touchPoint.y - center.y, touchPoint.x - center.x)
//////                                        element.rotation = Angle(radians: Double(radians))
//////                                        
//////                                        // 2. 計算等比例縮放（依據拖動距離與基準距離的比率）
//////                                        let distance = sqrt(pow(touchPoint.x - center.x, 2) + pow(touchPoint.y - center.y, 2))
//////                                        let baseDistance: CGFloat = 56.5 // 假設初始半徑基準值
//////                                        element.scale = max(0.5, distance / baseDistance) // 限制最小縮放比
//////                                    }
//////                            )
////                                                    
////                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
////                                .foregroundColor(.accentColor)
////                                .background(Circle().fill(Color.white))
////                                // 1. 依據當前型別倍率與縮放比例設定動態位移（右下角為正 X, 正 Y）
////                                .offset(x: (elementBaseSize.width / 2) * element.scale,
////                                                                    y: (elementBaseSize.height / 2) * element.scale)
////                                // 2. 隨元件整體角度進行旋轉變換
////                                .rotationEffect(element.rotation)
////                                // 3. 將控制鈕定位在畫布的絕對中心點上
////                                .position(element.position)
////                                // 4. 手勢追蹤與幾何運算
////                                .gesture(
////                                    DragGesture()
////                                        .onChanged { value in
////                                            let center = element.position
////                                            let touchPoint = value.location
////                                            
////                                            // 🟢 幾何公式依據一：動態計算右下角頂點相對於中心點的初始未旋轉夾角
////                                            let initialAngle = atan2(elementBaseSize.height / 2, elementBaseSize.width / 2)
////                                            // 計算手指拖曳點與中心點的絕對夾角
////                                            let currentRadians = atan2(touchPoint.y - center.y, touchPoint.x - center.x)
////                                            // 扣除初始夾角，得到純粹的旋轉弧度，防止手指按下的瞬間元件發生角度跳轉
////                                            element.rotation = Angle(radians: Double(currentRadians - initialAngle))
////                                            
////                                            // 🟢 幾何公式依據二：運用勾股定理動態算出未縮放前的半徑半邊長
////                                            let baseDistance = sqrt(pow(elementBaseSize.width / 2, 2) + pow(elementBaseSize.height / 2, 2))
////                                            // 計算當前手指到元件中心的真實物理距離
////                                            let currentDistance = sqrt(pow(touchPoint.x - center.x, 2) + pow(touchPoint.y - center.y, 2))
////                                            
////                                            // 動態設定等比例縮放比率
////                                            element.scale = currentDistance / baseDistance
////                                            
////                                            // 縮放時即時執行「旋轉外包圍框」限制，確保放大不越界
////                                            if element.type == .photo {
////                                                clampPhotoGeometry()
////                                            }
////                                        }
////                                )
////                    }
////                }
////            )
//    }
//    // 放在 ElementWrapperView 內部，用以計算與約束相片幾何狀態的私有函數
//    private func clampPhotoGeometry() {
//        guard element.type == .photo, let uiImage = element.rawImage else { return }
//        
//        let baseWidth = elementBaseSize.width
//        let baseHeight = elementBaseSize.height
//        
//        // 取得當前的旋轉弧度絕對值
//        let theta = element.rotation.radians
//        let cosT = abs(cos(theta))
//        let sinT = abs(sin(theta))
//        
//        // 幾何公式：計算矩形在經過 theta 角度旋轉後，外包圍框在 X 軸與 Y 軸上外擴的「最大半寬高」
//        let baseExtX = (baseWidth / 2) * cosT + (baseHeight / 2) * sinT
//        let baseExtY = (baseWidth / 2) * sinT + (baseHeight / 2) * cosT
//        
//        // 逆推在當前旋轉角度下，畫布（360x640）允許的最大安全縮放比，直接截斷過度放大的操作
//        let maxScaleX = 180.0 / baseExtX
//        let maxScaleY = 320.0 / baseExtY
//        let maxAllowedScale = min(maxScaleX, maxScaleY)
//        
//        if element.scale > maxAllowedScale {
//            element.scale = maxAllowedScale
//        }
//        if element.scale < 0.3 {
//            element.scale = 0.3 // 限制最小縮放
//        }
//        
//        // 結合最終確定的縮放值，求出最外邊緣的外擴半寬高
//        let extX = baseExtX * element.scale
//        let extY = baseExtY * element.scale
//        
//        // 運用外包圍框邊緣，夾擠並鎖死中心點 position 坐標
//        let minX = extX
//        let maxX = 360.0 - extX
//        let minY = extY
//        let maxY = 640.0 - extY
//        
//        element.position.x = min(max(element.position.x, minX), maxX)
//        element.position.y = min(max(element.position.y, minY), maxY)
//    }
//    
//}
//


//---------------------



struct CanvasTextView: View {
    @Binding var element: CanvasElement
    @FocusState var isKeyboardFocused: Bool
    let fonts = ["Helvetica", "Courier", "Papyrus", "Georgia"]
    @State private var istextAlignCenter: Bool = true
    
    var body: some View {
        ZStack {
            if element.isEditing {
                // 🔥 編輯狀態：顯示輸入框，允許打字
                TextField("請輸入文字", text: $element.content, axis: .vertical)
                    .font(.custom(element.fontName, size: 20))
                    .foregroundColor(element.color)
                    .focused($isKeyboardFocused)
                    .frame(maxWidth: 300, alignment: istextAlignCenter ? .center : .leading) // 限制固定寬度，讓文字滿了自動換行
                    .multilineTextAlignment(istextAlignCenter ? .center : .leading)
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
                                istextAlignCenter.toggle()
                            }label: {
                                Image(systemName: istextAlignCenter ? "text.alignleft" : "text.aligncenter")
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
                    .font(.custom(element.fontName, size: 20))
                    .foregroundColor(element.color)
                    .lineLimit(nil)
                    .frame(maxWidth: 300, alignment: istextAlignCenter ? .center : .leading) // 保持與編輯狀態相同的固定寬度
                    .multilineTextAlignment(istextAlignCenter ? .center : .leading)
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
                return CGSize(width: baseWidth + 50, height: baseHeight + 40)
            }
            return CGSize(width: 220, height: 220)
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
                                    position: CGPoint(x: 200, y: 300),
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
                    // 若有文字正在編輯，收起鍵盤
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            ForEach($elements) { $element in
                let isSelected = !isExporting && selectedElementID == element.id
                
                Group {
                    switch element.type {
                    case .text:
                        CanvasTextView(element: $element)
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
                            .stroke(element.color, lineWidth: 4)
                            .frame(width: element.doodleSize.width, height: element.doodleSize.height)
                            .contentShape(Rectangle())
                    }
                }
                .scaleEffect(element.scale)
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
                        selectedElementID = element.id
                    }
                    selectedElementID = element.id
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
                    .stroke(selectedDoodleColor, lineWidth: 4)
            }
        }
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
        // 因 position 手勢 value.location 是相對於螢幕，需要做點幾何判斷
        // 簡單的方式是在畫布上方放一個透明層攔截位置，或者根據畫布在螢幕上的位置進行換算。
        // 這裏假設 dragLocation 是相對於畫布 ZStack 座標系統。
        
        // 幾何依據：手指點的位置在畫布底部 80 像素內
        return point.y > (canvasSize.height - trashZoneHeight)
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
        } else if let selectedID = selectedElementID,
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






