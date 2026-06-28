//
//  FontPickerToolbarModifier.swift
//  WallpaperApp
//

import SwiftUI

struct FontPickerToolbarModifier: ViewModifier {
    @Binding var selectedFont: CustomFontOption
    @Binding var selectedTitleFont: CustomFontOption
    var isTitleFocused: FocusState<Bool>.Binding
    var isBodyFocused: FocusState<Bool>.Binding   // 新增 body 的 focus
    
    let fontOptions: [CustomFontOption]
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if isTitleFocused.wrappedValue || isBodyFocused.wrappedValue {
                    FontPickerToolbar(
                        selectedFont: $selectedFont,
                        selectedTitleFont: $selectedTitleFont,
                        fontOptions: fontOptions, isTitleFocused: isTitleFocused.wrappedValue
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
    }
}

// MARK: - Convenience Extension
extension View {
    func fontPickerToolbar(
        selectedFont: Binding<CustomFontOption>,
        selectedTitleFont: Binding<CustomFontOption>,
        isTitleFocused: FocusState<Bool>.Binding,
        isBodyFocused: FocusState<Bool>.Binding,
        fontOptions: [CustomFontOption] = FontManager.shared.fontOptions
    ) -> some View {
        self.modifier(
            FontPickerToolbarModifier(
                selectedFont: selectedFont,
                selectedTitleFont: selectedTitleFont,
                isTitleFocused: isTitleFocused,
                isBodyFocused: isBodyFocused,
                fontOptions: fontOptions
            )
        )
    }
}


