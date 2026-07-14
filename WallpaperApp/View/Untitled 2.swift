//
//  Untitled 2.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/8.
//

import SwiftUI
import Foundation
import CoreGraphics

// 儲存單個字母筆劃的中軸線頂點資料
struct HersheyCharacter {
    // 一個字母可能由多條獨立的「筆劃」組成，每條筆劃是一系列連續的點
    let strokes: [[CGPoint]]
    let width: CGFloat // 字體寬度（用於排版時計算下一個字的位置）
}

struct HersheyFont {
    // 這裡內建 A, B, C, L, O 的中軸線骨架數據
    static let glyphs: [Character: HersheyCharacter] = [
        "A": HersheyCharacter(strokes: [
            [CGPoint(x: 0, y: 0), CGPoint(x: 5, y: 14), CGPoint(x: 10, y: 0)], // 左橫跨到右
            [CGPoint(x: 2, y: 5), CGPoint(x: 8, y: 5)]                         // 中間那一橫
        ], width: 12),
        
        "B": HersheyCharacter(strokes: [
            [CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 14)],                       // 左側直線骨架
            [CGPoint(x: 1, y: 14), CGPoint(x: 6, y: 14), CGPoint(x: 8, y: 11), CGPoint(x: 6, y: 7), CGPoint(x: 1, y: 7)], // 上半圓
            [CGPoint(x: 1, y: 7), CGPoint(x: 7, y: 7), CGPoint(x: 9, y: 3.5), CGPoint(x: 7, y: 0), CGPoint(x: 1, y: 0)]   // 下半圓
        ], width: 11),
        
        "C": HersheyCharacter(strokes: [
            [CGPoint(x: 9, y: 11), CGPoint(x: 6, y: 14), CGPoint(x: 2, y: 11), CGPoint(x: 1, y: 7), CGPoint(x: 2, y: 3), CGPoint(x: 6, y: 0), CGPoint(x: 9, y: 3)] // 圓弧骨架
        ], width: 11),
        
        "L": HersheyCharacter(strokes: [
            [CGPoint(x: 1, y: 14), CGPoint(x: 1, y: 0), CGPoint(x: 8, y: 0)]   // 直角骨架
        ], width: 10),
        
        "O": HersheyCharacter(strokes: [
            [CGPoint(x: 5, y: 14), CGPoint(x: 1, y: 10), CGPoint(x: 1, y: 4), CGPoint(x: 5, y: 0), CGPoint(x: 9, y: 4), CGPoint(x: 9, y: 10), CGPoint(x: 5, y: 14)] // 閉合橢圓
        ], width: 11)
    ]
}




