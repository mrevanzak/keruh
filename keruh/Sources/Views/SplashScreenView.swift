//
//  SplashScreenView.swift
//  keruh
//
//  Created by Elizabeth Celine Liong on 14/07/25.
//

import SwiftUI

struct SplashScreenView: View {
    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            Image("logo homepage")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
                .transition(.scale)
                .matchedGeometryEffect(id: "title", in: namespace)
                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    struct SplashPreview: View {
        @Namespace private var namespace
        var body: some View {
            SplashScreenView(namespace: namespace)
        }
    }
    return SplashPreview()
}
