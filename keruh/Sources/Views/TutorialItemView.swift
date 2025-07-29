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
                .frame(width: 60, height: 60)
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
                        HStack {
                            Image("collect_kresek")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)

                            Text("+\(itemType.points)g")
                                .font(.figtree(size: 12))
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .padding(14)
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
        case "collect_ban": return "Ban Sepeda"
        case "collect_ciki": return "Bungkus Ciki"
        case "collect_sandal": return "Sandal Bekas"
        case "collect_popmie": return "Cup Mie Instan"
        case "power_extralive": return "Nyawa Ekstra"
        case "power_doublepoint": return "Poin Ganda"
        case "power_shield": return "Tameng Hati"
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
        case "power_shield": return "Mengurangi kecepatan jatuhnya barang"
        default: return ""
        }
    }

    var tutorialBackgroundColor: Color {
        if isSpecial {
            return .yellow
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
        }.sorted { $0.points < $1.points }
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

    @State private var scrollPosition: Int? = 0

    var body: some View {
        VStack(spacing: 12) {
            if #available(iOS 17.0, *) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items.indices, id: \.self) { index in
                            TutorialItemView(
                                itemType: items[index],
                                isAnimated: animateItems
                            )
                            .containerRelativeFrame(
                                .horizontal,
                                count: 3,
                                spacing: 8
                            )
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrollPosition)
            } else {
                // Fallback on earlier versions
            }

            if items.count > 3 {
                PageIndicatorView(
                    itemCount: items.count,
                    currentItem: scrollPosition ?? 0
                )
                .padding(.horizontal)
            }
        }
        .frame(height: 170)
    }
}

struct PageIndicatorView: View {
    let itemCount: Int
    let currentItem: Int

    private let cardsPerPage = 3

    private let themeColor = Color(
        red: 52 / 255,
        green: 168 / 255,
        blue: 197 / 255
    )
    private let trackColor = Color.secondary.opacity(0.3)

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)

                Capsule()
                    .fill(themeColor)
                    .frame(width: calculateProgressBarWidth(in: geometry.size))
                    .animation(.spring(), value: currentItem)
            }
        }
        .frame(height: 8)
    }

    private func calculateProgressBarWidth(in size: CGSize) -> CGFloat {
        guard itemCount > 0 else { return 0 }

        let lastVisibleItemIndex = currentItem + cardsPerPage - 1

        let clampedIndex = min(lastVisibleItemIndex, itemCount - 1)

        let progress = CGFloat(clampedIndex + 1) / CGFloat(itemCount)

        return size.width * progress
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

extension View {
    func offsetChanged(_ action: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("scroll")).minX
                    )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
