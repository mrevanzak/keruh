//
//  GameOverView.swift
//  keruh
//
//  Created by Elizabeth Celine Liong on 21/07/25.
//

import SwiftUI

struct GameOver: View {
    var body: some View {
        ZStack {
            Image("game_over")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                (Text("13.450 KG\n")
                    .font(.custom("PaperInko", size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(
                        Color(red: 251 / 255, green: 175 / 255, blue: 23 / 255)
                    )
                    + Text("SAMPAH LENYAP.\nDAN ITU,\nKARENA KAMU!")
                    .font(.custom("PaperInko", size: 28))
                    .fontWeight(.black)
                    .foregroundColor(.black))
                    .multilineTextAlignment(.center)

                Text("KALAU SEMUA ORANG KAYAK KAMU,\nBUMI BISA LEGA NAPASNYA!")
                    .font(.custom("PaperInko", size: 14))
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(
                        Color(red: 51 / 255, green: 178 / 255, blue: 199 / 255)
                    )
            }
            .padding(.top, 86)
            
            VStack() {
                HStack(spacing: 32) {
                    Button(action: {
                    }) {
                        Image("replay")
                            .resizable()
                            .frame(width: 72, height: 72)
                    }

                    Button(action: {
                    }) {
                        Image("home")
                            .resizable()
                            .frame(width: 72, height: 72)
                    }
                }
            }
            
            .padding(.top, 372)
            
        }
        .padding(.horizontal, 16)
        
    }
}

#Preview {
    GameOver()
}
