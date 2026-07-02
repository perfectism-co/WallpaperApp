//
//  FontPickerToolbarModifier.swift
//  WallpaperApp
//

import SwiftUI


struct FontPickerToolbarModifier: ViewModifier {
    @Binding var selectedFont: CustomFontOption
    @Binding var selectedTitleFont: CustomFontOption
    @Binding var selectedTapeColor: TapeColorOption
    @Binding var selectedCard: CardType
    
    var isTitleFocused: FocusState<Bool>.Binding
    var isBodyFocused: FocusState<Bool>.Binding
    
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if isTitleFocused.wrappedValue || isBodyFocused.wrappedValue {
                    FontPickerToolbar(
                        selectedFont: $selectedFont,
                        selectedTitleFont: $selectedTitleFont,
                        selectedTapeColor: $selectedTapeColor, selectedCard: $selectedCard,
                        isTitleFocused: isTitleFocused.wrappedValue
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
        selectedTapeColor: Binding<TapeColorOption>,
        selectedCard: Binding<CardType>,
        isTitleFocused: FocusState<Bool>.Binding,
        isBodyFocused: FocusState<Bool>.Binding
    ) -> some View {
        self.modifier(
            FontPickerToolbarModifier(
                selectedFont: selectedFont,
                selectedTitleFont: selectedTitleFont,
                selectedTapeColor: selectedTapeColor, selectedCard: selectedCard,
                isTitleFocused: isTitleFocused,
                isBodyFocused: isBodyFocused
            )
        )
    }
}
