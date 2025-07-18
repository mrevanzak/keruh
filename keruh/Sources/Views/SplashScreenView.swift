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
            Text("KERUH")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.white)
                .fixedSize()
                .matchedGeometryEffect(id: "title", in: namespace)
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
