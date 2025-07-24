//
//  LeaderboardTopThreeView.swift
//  keruh
//
//  Created by Richie Reuben Hermanto on 23/07/25.
//

import SwiftUI

struct LeaderboardTopThreeView: View {
    var rank: Int
    var name: String
    var score: Int
    var image: UIImage? = nil
    var rankFrameImage: Image = Image("rankframe_rank1")
    var borderRankImage: Image = Image("border_rank1")
    var scoreViewImage: Image = Image("score_view")
    
    var body: some View {
        ZStack {
            borderRankImage
                .resizable()
                .frame(width: 150, height: 150)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .offset(x:-2)
                    .offset(y:1)
                
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .offset(x:-2)
                    .offset(y:1)
            }
            ZStack {
                rankFrameImage
                    .resizable()
                    .frame(width: 60, height: 60)
                Text("\(rank)")
                    .font(.figtree(size: 20))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .offset(x:-4)
                    .offset(y:-2)
            }
            .offset(y: -55)
            ZStack {
                scoreViewImage
                    .resizable()
                    .frame(width: 100, height: 30)
                    .cornerRadius(10)
                HStack(spacing: 8) {
                    Text("\(score) kg")
                        .font(.figtree(size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .offset(x: 7)
                }
            }
            .offset(y: 55)
            Text(name)
                .font(.figtree(size: 16))
                .fontWeight(.bold)
                .foregroundColor(.teal)
                .offset(y: 85)
        }
        .scaledToFit()
    }
}

#Preview {
    LeaderboardTopThreeView(
        rank: 1,
        name: "Joko",
        score: 23212
    )
}
