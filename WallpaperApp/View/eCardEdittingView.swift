
import SwiftUI
import PhotosUI




struct CanvasView: View {
    @State private var elements: [CanvasElement] = []
    @State private var selectedElementID: UUID? = nil
    @State private var showStickerSheet = false
    @State private var stickerGlobalColor = Color.black
    @State private var isShowExportOutline = false
    
    // 照片選擇器狀態
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var showPhotoLimitAlert = false
    
    // 塗鴉狀態控制
    @State private var isDrawingMode = false
    @State private var currentStroke: [CGPoint] = []          // 🟢 目前手指正拖動、尚未放開的單一筆跡
    @State private var sessionStrokes: [[CGPoint]] = []       // 🟢 這一輪塗鴉模式下，放開手指後累積的所有筆跡 (Undo 堆疊)
    @State private var redoStrokesHistory: [[CGPoint]] = [] // 🟢 存放被撤銷筆跡的歷史紀錄 (Redo 堆疊)
    @State private var selectedDoodleColor: Color = .black
    
    // 🟢 新增：用於控制是否正在導出圖片的狀態
    @State private var shareItem: ShareItem? = nil
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.init(cgColor: .init(gray: 0.85, alpha: 1)).ignoresSafeArea()
                    
                // 畫布區域
                canvasBody(isExporting: false) // 平時顯示的正常畫布
                
                // 下方功能操作列
                VStack{
                    Spacer()
                    bottomInspectorPanel
                    //ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            PhotosPicker(selection: $selectedPickerItem, matching: .images) {
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Photo")
                                }.frame(width: 70, height: 50)
                            }
                            .onChange(of: selectedPickerItem) { oldValue, newValue in
                                guard let newValue = newValue else { return }
                                
                                Task {
                                    if let data = try? await newValue.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        await MainActor.run {
                                            // 🟢 修正二：尋找是否已存在照片元件
                                            if let index = elements.firstIndex(where: { $0.type == .photo }) {
                                                // 若存在，直接替換圖片內容，並重設濾鏡
                                                elements[index].rawImage = uiImage
                                                elements[index].filter = .none
                                                selectedElementID = elements[index].id
                                            } else {
                                                // 若不存在，才建立新的相片元件
                                                let newPhoto = CanvasElement(
                                                    type: .photo,
                                                    content: "",
                                                    position: CGPoint(x: 180, y: 320),
                                                    rawImage: uiImage
                                                )
                                                elements.append(newPhoto)
                                                selectedElementID = newPhoto.id
                                            }
                                            selectedPickerItem = nil // 重設選取器狀態
                                        }
                                    }
                                }
                            }
                            
                                                        
//                            Button {
//                               
//                            }label: {
//                                VStack {
//                                    Image(systemName: "camera.filters")
//                                        .font(.system(size: 18, weight: .bold))
//                                    Text("Filter")
//                                }.frame(width: 70, height: 50)
//                            }
                            
                            Button {
                                let newText = CanvasElement(
                                    type: .text,
                                    content: "請輸入文字",
                                    position: CGPoint(x: 180, y: 320),
                                    isEditing: true // 🔴 關鍵：一開始新增就是編輯狀態
                                )
                                elements.append(newText)
                                selectedElementID = newText.id
                            }label: {
                                VStack {
                                    Image(systemName: "character.textbox")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("Text").font(.footnote)
                                }.frame(width: 70, height: 50)
                            }
                            
                            Button {
                                showStickerSheet = true
                            }label: {
                                VStack {
                                    Image(systemName: "seal")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Sticker")
                                }.frame(width: 70, height: 50)
                            }
                            
                            Button {
                               
                            }label: {
                                VStack {
                                    Image(systemName: "camera.macro.circle")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Object")
                                }.frame(width: 70, height: 50)
                            }
                            
                            Button {
                                if isDrawingMode {
                                    // 🟢 核心修正：當關閉塗鴉狀態時，將之前畫的所有筆跡轉換成一個物件
                                    convertSessionToDoodleElement()
                                    isDrawingMode = false
                                } else {
                                    isDrawingMode = true
                                }
                            }label: {
                                VStack {
                                    Image(systemName: "pencil.and.scribble")
                                        .font(.system(size: 18, weight: .bold))
                                    Text(isDrawingMode ? "Off" : "Draw")
                                }.frame(width: 70, height: 50)
                                .foregroundColor(isDrawingMode ? .red : .blue)
                            }
                        }
                        .font(.footnote)
                        .padding()
                    }
                }
                
                
            //}
            .sheet(isPresented: $showStickerSheet) {
                StickerSheetView(
                    selectedColor: $stickerGlobalColor,
                    stickerAssets: ["stick", "sticker_heart", "sticker_cat"], // 對應 Asset 內的 SVG 名稱
                    onSelect: { chosenAsset in
                        let newSticker = CanvasElement(
                            type: .sticker,
                            content: chosenAsset,
                            position: CGPoint(x: 180, y: 320),
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
                
                    Label("Export Outline", systemImage: "square.dashed")
                
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            // 當手指碰觸並停留時，若尚未進入按壓狀態則觸發
                            if !isShowExportOutline {
                                isShowExportOutline = true
                            }
                        }
                        .onEnded { _ in
                            // 當手指離開螢幕時觸發
                            isShowExportOutline = false
                        }
                )
                
                Button(action: {
                    // 🟢 觸發渲染與分享邏輯
                    renderAndShareCanvas()
                    
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
    // 🟢 將畫布本體抽離成獨立函數，以便重複調用（正常顯示 vs 導出渲染）
    private func canvasBody(isExporting: Bool) -> some View {
        ZStack {
            Color.init(cgColor: .init(gray: 0.85, alpha: 1))
                .onTapGesture {
                    selectedElementID = nil // 點擊空白處取消選取
                }
            
            ForEach($elements) { $element in
                ElementWrapperView(
                    content: {
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
                                // 調用濾鏡處理器即時渲染
                                Image(uiImage: FilterProcessor.shared.applyFilter(to: rawImage, filterType: element.filter))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200) // 設定照片參考寬度
                                    .padding(10)
                                    .padding(.bottom, 20)
                                    .background(Color.white)
                                    .compositingGroup()
                            }
                            
                        case .doodle:
                            // 繪製歸一化後的塗鴉物件
                            DoodleShape(strokes: element.doodleStrokes)
                                .stroke(element.color, lineWidth: 4)
                                .frame(width: element.doodleSize.width, height: element.doodleSize.height)
                                // 🟢 核心修正：將滑鼠與手指觸及區域擴大至此物件的整個 Frame 矩形範圍
                                .contentShape(Rectangle())
                        }
                    },
                    element: $element,
                    isSelected: isExporting ? false : (selectedElementID == element.id),
                    isDrawingMode: isDrawingMode,
                    onDelete: {
                        // 🟢 當上方的 switch 修正後，此處的 removeAll 將恢復正常編譯
                        elements.removeAll { $0.id == element.id }
                    }
                )
                .onTapGesture {
                    selectedElementID = element.id // 點擊物件切換為選取狀態
                }
            }
            
            // 🔴 塗鴉手勢攔截層
            if isDrawingMode {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // 🟢 正在畫時，將點加入當前這一筆筆跡中
                                currentStroke.append(value.location)
                            }
                            .onEnded { _ in
                                // 🟢 手指抬起時，將這一筆存入 session 暫存區，並清空重做歷史
                                if !currentStroke.isEmpty {
                                    sessionStrokes.append(currentStroke)
                                    currentStroke.removeAll()
                                    redoStrokesHistory.removeAll()
                                }
                            }
                    )
                
                // 🟢 即時渲染：畫布上已畫好的筆跡 + 目前正在畫的這一筆
                DoodleShape(strokes: sessionStrokes + [currentStroke])
                    .stroke(selectedDoodleColor, lineWidth: 4)
            }
        }
        .frame(width: 360, height: 640)
        .clipped()
        .overlay {
            if isShowExportOutline{
                Rectangle()
                    .stroke()
            }
        }
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
            // 塗鴉模式下：顯示顏色選擇器
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
                  let index = elements.firstIndex(where: { $0.id == selectedID }) {
            
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
    CanvasView()
}




