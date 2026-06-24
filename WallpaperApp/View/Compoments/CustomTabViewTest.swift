import SwiftUI

//enum Taba: String, CaseIterable, Identifiable {
//    case explore = "Explore"
//    case library = "Library"
//    case profile = "Profile"
//    
//    var id: String { rawValue }
//    
//    
//}
//
//struct CustomTabView: View {
//    @State private var selectedTab: Taba = .explore
//    @State private var dragOffset: CGFloat = 0
//    @State private var isDragging = false
//    @State private var isSwipeTransition = false  // 控制是否使用滑動動畫
//    
//    private let tabs: [Taba] = [.explore, .library, .profile]
//    
//    var body: some View {
//        ZStack {
//            GeometryReader { geometry in
//                HStack(spacing: 0) {
//                    ForEach(tabs) { tab in
//                        tabContent(for: tab)
//                            .frame(width: geometry.size.width, height: geometry.size.height)
//                            .contentShape(Rectangle())
//                    }
//                }
//                .offset(x: calculateOffset(geometry: geometry))
//                .animation(
//                    isDragging || isSwipeTransition
//                    ? .spring(response: 0.45, dampingFraction: 0.78)
//                    : nil,
//                    value: selectedTab
//                )
//                .gesture(
//                    DragGesture(minimumDistance: 10)
//                        .onChanged { value in
//                            isDragging = true
//                            isSwipeTransition = true
//                            dragOffset = value.translation.width
//                        }
//                        .onEnded { value in
//                            let width = geometry.size.width
//                            let index = tabs.firstIndex(of: selectedTab) ?? 0
//                            let threshold = width * 0.35
//                            
//                            var newTab = selectedTab
//                            
//                            if value.translation.width > threshold && index > 0 {
//                                newTab = tabs[index - 1]
//                            } else if value.translation.width < -threshold && index < tabs.count - 1 {
//                                newTab = tabs[index + 1]
//                            }
//                            
//                            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
//                                selectedTab = newTab
//                                dragOffset = 0
//                            }
//                            
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                isDragging = false
//                                isSwipeTransition = false
//                            }
//                        }
//                )
//            }
//            
//            VStack {
//                CustomBottomTabBar(selectedTab: $selectedTab, onTabTap: handleTabTap)
//                Spacer()
//            }
//        }
//        .ignoresSafeArea(edges: .bottom)
//    }
//    
//    private func handleTabTap(newTab: Taba) {
//        guard newTab != selectedTab else { return }
//        
//        isSwipeTransition = false
//        dragOffset = 0
//        
//        // 點擊切換時不使用滑動動畫，直接切換
//        withAnimation(nil) {  // 或 .default / .easeInOut
//            selectedTab = newTab
//        }
//    }
//    
//    private func calculateOffset(geometry: GeometryProxy) -> CGFloat {
//        let index = CGFloat(tabs.firstIndex(of: selectedTab) ?? 0)
//        let baseOffset = -index * geometry.size.width
//        return baseOffset + dragOffset
//    }
//    
//    @ViewBuilder
//    private func tabContent(for tab: Taba) -> some View {
//        switch tab {
//        case .explore: ExploreView()
//        case .library: LibraryView()
//        case .profile: ProfileView()
//        }
//    }
//}
//// MARK: - 自訂底部 Tab Bar
//struct CustomBottomTabBar: View {
//    @Binding var selectedTab: Taba
//    var onTabTap: (Taba) -> Void   // 新增
//    
//    var body: some View {
//        HStack(spacing: 20) {
//            TabBarButton(tab: .explore, selectedTab: $selectedTab, onTap: onTabTap)
//            TabBarButton(tab: .library, selectedTab: $selectedTab, onTap: onTabTap)
//            TabBarButton(tab: .profile, selectedTab: $selectedTab, onTap: onTabTap)
//        }
//        .padding(.horizontal, 24)
//        .padding(.bottom, 12)
//        
//    }
//}
//
//struct TabBarButton: View {
//    let tab: Taba
//    @Binding var selectedTab: Taba
//    var onTap: (Taba) -> Void
//    
//    var body: some View {
//        Button {
//            onTap(tab)
//        } label: {
//            Text(tabTitle(for: tab))
//                .font(.callout)
//                .padding(.horizontal, 16)
//                .padding(.vertical, 12)
//                .glassEffect(.clear.tint(selectedTab == tab ? .white.opacity(0.6) : .black.opacity(0.4)))
//                .foregroundStyle(selectedTab == tab ? .black : .secondary)
//        }
//    }
//    
//    private func tabTitle(for tab: Taba) -> String {
//        switch tab {
//        case .explore: return "探索"
//        case .library: return "收藏"
//        case .profile: return "我的"
//        }
//    }
//}
//// MARK: - 範例頁面
//struct ExploreView: View {
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
//                ForEach(0..<20) { _ in
//                    Rectangle()
//                        .fill(Color.gray.opacity(0.3))
//                        .aspectRatio(1, contentMode: .fill)
//                        .overlay(
//                            Text("Wallpaper")
//                                .foregroundStyle(.white)
//                                .shadow(radius: 3)
//                        )
//                }
//            }
//        }
//    }
//}
//
//struct LibraryView: View {
//    var body: some View {
////        Color.orange.opacity(0.1)
////            .overlay(Text("Library / 收藏").font(.largeTitle))
//        ScrollView{
//            Image("myImageName").resizable()
//        }
//    }
//}
//
//struct ProfileView: View {
//    var body: some View {
//        Color.purple.opacity(0.1)
//            .overlay(Text("Profile").font(.largeTitle))
//    }
//}

// Preview
//#Preview {
//    CustomTabView()
//        
//}

