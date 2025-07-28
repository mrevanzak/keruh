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

    @State private var currentPage: Int = 0

    private let cardsPerPage = 3
    private let spacing: CGFloat = 8
    private let horizontalPadding: CGFloat = 4

    var totalPages: Int {
        max(1, Int(ceil(Double(items.count) / Double(cardsPerPage))))
    }

    var body: some View {
        VStack {
            GeometryReader { geo in
                let cardWidth =
                    (geo.size.width - (spacing * CGFloat(cardsPerPage - 1)) - 2
                        * horizontalPadding) / CGFloat(cardsPerPage)

                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        HStack(spacing: spacing) {
                            ForEach(items.indices, id: \.self) { index in
                                TutorialItemView(
                                    itemType: items[index],
                                    isAnimated: animateItems
                                )
                                .frame(width: cardWidth)
                                .id(index)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .offsetChanged { offset in
                            let totalCardWidth = cardWidth + spacing
                            let rawPage =
                                (offset + horizontalPadding)
                                / (totalCardWidth * CGFloat(cardsPerPage))
                            let newPage = Int(round(rawPage))
                            if newPage != currentPage {
                                currentPage = min(
                                    max(newPage, 0),
                                    totalPages - 1
                                )
                            }
                        }
                    }
                }
            }
            .frame(height: 160)
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
