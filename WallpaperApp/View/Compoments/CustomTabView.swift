


import SwiftUI




 // MARK: - 可重複使用的 Tab View 套件
struct ReusableTabView<Tab: Hashable, Content: View, Content2: View>: View {
    let tabs: [Tab]
        
    @Binding var selectedTab: Tab
    var isTabBarScrollable: Bool
    var tabTitle: (Tab) -> String
    
    let content: (Tab) -> Content
    let content2: () -> Content2 // 2. 宣告回傳 Content2 的閉包
    
    // 3. 自訂建構子：必須把「所有」屬性都放進來初始化！
    init(
        tabs: [Tab],
        selectedTab: Binding<Tab>, // Binding 在 init 的型別寫法
        isTabBarScrollable: Bool,
        tabTitle: @escaping (Tab) -> String,
        @ViewBuilder content: @escaping (Tab) -> Content,
        @ViewBuilder content2: @escaping () -> Content2 // 加上 @ViewBuilder
    ) {
        self.tabs = tabs
        self._selectedTab = selectedTab // 綁定 Binding 屬性要加底線 _
        self.isTabBarScrollable = isTabBarScrollable
        self.tabTitle = tabTitle
        self.content = content
        self.content2 = content2
    }
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var isSwipeTransition = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Page
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        content(tab)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .contentShape(Rectangle())
                    }
                }
                .offset(x: calculateOffset(geometry: geometry))
                .animation(
                    isDragging || isSwipeTransition
                    ? .spring(response: 0.45, dampingFraction: 0.78)
                    : nil,
                    value: selectedTab
                )
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            isDragging = true
                            isSwipeTransition = true
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let width = geometry.size.width
                            let index = tabs.firstIndex(of: selectedTab) ?? 0
                            let threshold = width * 0.35
                            
                            var newTab = selectedTab
                            
                            if value.translation.width > threshold && index > 0 {
                                newTab = tabs[index - 1]
                            } else if value.translation.width < -threshold && index < tabs.count - 1 {
                                newTab = tabs[index + 1]
                            }
                            
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                                selectedTab = newTab
                                dragOffset = 0
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isDragging = false
                                isSwipeTransition = false
                            }
                        }
                )
            }
            // TabBar
            VStack {
                ReusableBottomTabBar(
                    tabs: tabs,
                    selectedTab: $selectedTab,
                    isScrollable: isTabBarScrollable,
                    tabTitle: tabTitle,
                    onTabTap: handleTabTap
                )
                                   
                Spacer()
                
                
                content2()
                
            }
        }
    }
    
    private func handleTabTap(newTab: Tab) {
        guard newTab != selectedTab else { return }
        
        isSwipeTransition = false
        dragOffset = 0
        
        withAnimation(nil) {
            selectedTab = newTab
        }
    }
    
    private func calculateOffset(geometry: GeometryProxy) -> CGFloat {
        // 因為 Tab 泛型符合 Hashable/Equatable，可以使用 firstIndex(of:)
        let index = CGFloat(tabs.firstIndex(of: selectedTab) ?? 0)
        let baseOffset = -index * geometry.size.width
        return baseOffset + dragOffset
    }
}

// MARK: - 可重複使用的頂部 Tab Bar
struct ReusableBottomTabBar<Tab: Hashable>: View {
    let tabs: [Tab]
    @Binding var selectedTab: Tab
    let isScrollable: Bool
    let tabTitle: (Tab) -> String
    var onTabTap: (Tab) -> Void
    
    var body: some View {
        Group {
            ScrollViewReader { proxy in
                
                if isScrollable {
                    ScrollView(.horizontal, showsIndicators: false) {
                        tabButtons
                            .onChange(of: selectedTab) { _, newTag in
                                withAnimation {
                                    proxy.scrollTo(newTag, anchor: .center)
                                }
                            }
                    }
                } else {
                    tabButtons
                }
            }
        }
        .padding(.top, 12) // 根據需求調整間距
    }
    
    // 將按鈕群組提取出來，避免重複程式碼
    private var tabButtons: some View {
        GlassEffectContainer {
            HStack(spacing: 20) {
                ForEach(tabs, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        selectedTab: $selectedTab,
                        title: tabTitle(tab),
                        onTap: onTabTap
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - 單一 Tab 按鈕
struct TabBarButton<Tab: Equatable>: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    let title: String
    var onTap: (Tab) -> Void
    
    var body: some View {
        Button {
            onTap(tab)
        } label: {
            Text(title)
                .font(.callout)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.clear.tint(selectedTab == tab ? .white.opacity(0.6) : .black.opacity(0.4)).interactive())
                .foregroundStyle(selectedTab == tab ? .black : .white)
        }
    }
}



//// MARK: - 可重複使用的 Tab View 套件
//struct ReusableTabView<Tab: Hashable, Content: View>: View {
//    let tabs: [Tab]
//    @Binding var selectedTab: Tab
//    var isTabBarScrollable: Bool
//    var tabTitle: (Tab) -> String
//    @ViewBuilder var content: (Tab) -> Content
//    
//    var body: some View {
//        ZStack {
//            
//            // 1. 使用原生 TabView 替換 GeometryReader + HStack + DragGesture
//            TabView(selection: $selectedTab) {
//                ForEach(tabs, id: \.self) { tab in
//                    content(tab)
//                        // 2. 必須加上 tag，TabView 才能正確識別當前選擇的頁面
//                        .tag(tab)
//                        // 清除預設邊距，確保內容填滿
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                }
//            }
//            // 3. 設定為分頁模式，且隱藏預設的底部小圓點 (index display mode: .never)
////            .tabViewStyle(.page(indexDisplayMode: .never))
//            // 讓透過 Tab Bar 點擊的切換也能帶有動畫
////            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: selectedTab)
//            
//            // 4. 自訂底部 Tab Bar 放置於 TabView 上方
//            VStack{
//                ReusableBottomTabBar(
//                    tabs: tabs,
//                    selectedTab: $selectedTab,
//                    isScrollable: isTabBarScrollable,
//                    tabTitle: tabTitle,
//                    onTabTap: handleTabTap
//                )
//                Spacer()
//            }
//        }
//        .ignoresSafeArea(.all)
//    }
//    
//    private func handleTabTap(newTab: Tab) {
//        guard newTab != selectedTab else { return }
//            selectedTab = newTab
//        // 點擊底部按鈕時的切換動畫
////        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
////            selectedTab = newTab
////        }
//    }
//}













// 去別的頁面請這樣寫
// MARK: - 實際使用範例頁面
enum wTab: String, CaseIterable {
    case explore = "探索"
    case library = "收藏"
    case profile = "我的"
    case settings = "設定"
    case notifications = "通知"
}

struct DemoView: View {
    @State private var currentTab: wTab = .explore
    
    // 設定是否需要水平滑動。當 Tab 數量多時設為 true
    let enableScrollableTab = true
    
    var body: some View {
        // 呼叫可重複使用的套件
        ReusableTabView(
            tabs: wTab.allCases,
            selectedTab: $currentTab, // 移除了原本沒定義的 theText
            isTabBarScrollable: enableScrollableTab,
            tabTitle: { tab in tab.rawValue }
        ) { tab in
            // 第一個閉包：對應 content(tab) 的分頁畫面
            switch tab {
            case .explore:
                ExploreView()
            case .library:
                LibraryView()
            case .profile:
                ProfileView()
            case .settings:
                Color.blue.opacity(0.2).overlay(Text("設定頁面"))
            case .notifications:
                Color.green.opacity(0.2).overlay(Text("通知頁面"))
            }
        } content2: {
            // 第二個閉包：對應 content2() 的底部置底自訂內容
            VStack {
                Text("✨ 這是從外部傳入的 content2 內容")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
        }
    }
}





















// MARK: - 範例分頁
struct ExploreView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20), // 設定第一個與第二個之間的水平間距
                GridItem(.flexible(), spacing: 20)  // 左右間距會由這裡的 spacing 決定
            ], spacing: 10) {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay(
                            Text("Wallpaper")
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                        )
                }
            }
        }
    }
}

struct LibraryView: View {
    var body: some View {
//        Color.orange.opacity(0.1)
//            .overlay(Text("Library / 收藏").font(.largeTitle))
        ScrollView{
            Image("myImageName").resizable()
        }
    }
}

struct ProfileView: View {
    var body: some View {
        Color.purple.opacity(0.1)
            .overlay(Text("Profile").font(.largeTitle))
    }
}

#Preview {
    DemoView()
}

