import SwiftUI

struct TutorialItemView: View {
    let itemType: FallingObjectType
    let isAnimated: Bool
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
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

            VStack(alignment: .leading, spacing: 4) {
                Text(itemType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if !itemType.isCollectible && !itemType.isSpecial {
                    Text("Damages health!")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                } else if itemType.points > 0 {
                    Text("+\(itemType.points) points")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                } else {
                    Text(itemType.tutorialDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(itemType.tutorialBackgroundColor.opacity(0.1))
                .stroke(
                    itemType.tutorialBackgroundColor.opacity(0.6),
                    lineWidth: 2
                )
        )
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
        case "botol": return "Bottles"
        case "kaleng": return "Cans"
        case "kresek": return "Plastic Bags"
        case "ban": return "Tires"
        case "ciki": return "Snack Wrappers"
        case "sandal": return "Sandals"
        case "popok": return "Diapers"
        case "heart": return "Health"
        case "coin": return "Double Points"
        case "clock": return "Slow Motion"
        default: return "Unknown Item"
        }
    }

    var tutorialDescription: String {
        switch assetName {
        case "heart": return "Restores health"
        case "coin": return "2x points for 10s"
        case "clock": return "Slows falling items"
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
    let title: String
    let items: [FallingObjectType]
    let animateItems: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(items.indices, id: \.self) { index in
                    TutorialItemView(
                        itemType: items[index],
                        isAnimated: animateItems
                    )
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
                    title: "Clean Items to Catch:",
                    items: FallingObjectType.collectibles,
                    animateItems: true
                )
            }
            .padding()
        }
    }

    return TutorialItemPreview()
}
