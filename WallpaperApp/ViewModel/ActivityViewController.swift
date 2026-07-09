//
//  ActivityViewController.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/7.
//

import SwiftUI
import UIKit

// 用於在 SwiftUI 中呼叫 iOS 系統原生分享選單的工具
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
