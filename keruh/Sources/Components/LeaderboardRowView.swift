//
//  LeaderboardRowView.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 22/07/25.
//

import SwiftUI

struct LeaderboardRowView: View {
    var rank: Int
    var name: String
    var score: Int
    var backgroundImage: Image = Image("frame_rank4 kebawah")
    var rankBackgroundImage: Image = Image("tempat_angka")
    
    var body: some View {
        ZStack {
            backgroundImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 90)
                .cornerRadius(20)
                .clipped()
            
            HStack {
                ZStack {
                    rankBackgroundImage
                        .resizable()
                        .frame(width: 45, height: 45)
                    
                    Text("\(rank)")
                        .font(.figtree(size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(name)
                    .font(.figtree(size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.leading, 10)
                
                Spacer()
                
                ZStack {
                    Image("score_view")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 45)
                        .cornerRadius(10)
                    
                    HStack(spacing: 8) {
                        Text("\(score) kg")
                            .font(.figtree(size: 22))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .offset(x:12)
                    }
                    .padding(.horizontal, 12)
                }
                .fixedSize()
            }
            .offset(y: -4)
            .padding(.horizontal, 30)
        }
        .frame(height: 40)
    }
}


#Preview {
    VStack(spacing: 1){
        LeaderboardRowView(rank: 1, name: "Elizabeth", score: 122467)
            .scaleEffect(0.8)
    }
    
}
