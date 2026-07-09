//
//  Untitled 2.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/8.
//

import SwiftUI

struct Untitled_2: View {
    
    var body: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            Text("123")
                   .offset(x: -50, y: 80)
            Text("1456")
                    .offset(x: 50, y: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    Untitled_2()
}


struct Untitled_3: View {
    var body: some View {
        ZStack {
            Untitled_2()
                .scaledToFit()
        }
        .frame(width: 400, height: 800)
        .background(Color.red)
        .clipped()
    }
}

#Preview {
    Untitled_3()
}
