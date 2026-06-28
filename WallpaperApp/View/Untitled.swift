//
//  Untitled.swift
//  WallpaperApp
//
//  Created by macmini on 2026/6/27.
//

import UIKit
import SwiftUI


func snapshot(view: UIView) -> UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
    return renderer.image { context in
        view.layer.render(in: context.cgContext)
    }
}



