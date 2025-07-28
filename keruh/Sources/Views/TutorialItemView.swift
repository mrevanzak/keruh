import SwiftUI

struct TutorialItemView: View {
    let itemType: FallingObjectType
    let isAnimated: Bool
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(spacing: 8) {
                // Item image
                AsyncImage(url: nil) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(itemType.assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 40)
                .offset(y: isAnimated ? animationOffset : 0)
                .onAppear {
                    if isAnimated {
                        startAnimation()
                    }
                }

                VStack(spacing: 4) {
                    Text(itemType.displayName)
                        .font(.figtree(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                   if itemType.points > 0 {
                        Text("+\(itemType.points) gram")
                            .font(.figtree(size: 12))
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(itemType.tutorialBackgroundColor.opacity(0.1))
                    .stroke(
                        itemType.tutorialBackgroundColor.opacity(0.6),
                        lineWidth: 2
                    )
            )
        } else {
            // Fallback on earlier versions
        }
    }

    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        ) {
            animationOffset = -8
        }
    }
}

// Extension to add tutorial-specific properties to FallingObjectType
extension FallingObjectType {
    var displayName: String {
        switch assetName {
        case "collect_botol": return "Botol Plastik"
        case "collect_kaleng": return "Kaleng Soda"
        case "collect_kresek": return "Kantong Sampah"
        case "collect_ban": return "Ban"
        case "collect_ciki": return "Bungkus Ciki"
        case "collect_sandal": return "Sandal Bekas"
        case "collect_popmie": return "Cup Mie Instan"
        case "power_extralive": return "Nyawa Ekstra"
        case "power_doublepoint": return "Poin Ganda"
        case "power_slowdown": return "Tameng Hati"
        case "noncollect_gabus": return "Gabus"
        case "noncollect_ganggang": return "Ganggang"
        case "noncollect_lele": return "Lele"
        case "noncollect_nila": return "Nila"
        case "noncollect_teratai": return "Teratai"
        default: return "Unknown Item"
        }
    }

    var tutorialDescription: String {
        switch assetName {
        case "power_extralive": return "Tambahkan nyawa"
        case "power_doublepoint": return "Dua kali poin untuk 10 detik"
        case "power_slowdown": return "Mengurangi kecepatan jatuhnya barang"
        default: return ""
        }
    }

    var tutorialBackgroundColor: Color {
        if isSpecial {
            return .blue
        } else if isCollectible {
            return .green
        } else {
            return .red
        }
    }

    // Static collections for tutorial sections
    static var collectibles: [FallingObjectType] {
        return FallingObjectType.allTypes.filter {
            $0.isCollectible && !$0.isSpecial
        }
    }

    static var harmful: [FallingObjectType] {
        return FallingObjectType.allTypes.filter { !$0.isCollectible }
    }

    static var powerUps: [FallingObjectType] {
        return FallingObjectType.allTypes.filter { $0.isSpecial }
    }
}

struct TutorialItemsSection: View {
    let items: [FallingObjectType]
    let animateItems: Bool

    var body: some View {
        VStack(spacing: 8) {
            row(for: Array(items.prefix(3)), columns: 3)

            if items.count > 3 {
                row(for: Array(items[3..<min(items.count, 5)]), columns: 2)
            }

            if items.count > 5 {
                row(for: Array(items[5..<min(items.count, 7)]), columns: 2)
            }
        }
    }

    @ViewBuilder
    private func row(for rowItems: [FallingObjectType], columns: Int)
        -> some View
    {
        HStack(spacing: 8) {
            ForEach(rowItems.indices, id: \.self) { index in
                TutorialItemView(
                    itemType: rowItems[index],
                    isAnimated: animateItems
                )
                .frame(maxWidth: .infinity)
            }

            if rowItems.count < columns {
                ForEach(0..<(columns - rowItems.count), id: \.self) { _ in
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview {
    struct TutorialItemPreview: View {
        var body: some View {
            VStack(spacing: 20) {
                TutorialItemView(itemType: .bottle, isAnimated: true)
                TutorialItemView(itemType: .tire, isAnimated: true)
                TutorialItemView(itemType: .heart, isAnimated: true)

                TutorialItemsSection(
                    items: FallingObjectType.collectibles,
                    animateItems: true
                )
            }
            .padding()
        }
    }

    return TutorialItemPreview()
}
