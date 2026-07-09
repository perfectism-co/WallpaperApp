//
//  CardComponentType.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/7.
//

import SwiftUI

// 定義元件類型
enum CardComponentType: Identifiable, Equatable {
    case text(id: UUID, text: String)
    case image(id: UUID, image: UIImage?)
    
    var id: UUID {
        switch self {
        case .text(let id, _): return id
        case .image(let id, _): return id
        }
    }
}

// 定義貼紙模型（自由擺放）
struct StickerComponent: Identifiable {
    let id = UUID()
    let imageName: String
    var center: CGPoint
}
