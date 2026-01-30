import SwiftUI

/// 星級評分元件
struct StarRatingView: View {
    @Binding var rating: Int
    let maxRating: Int
    let starSize: CGFloat
    let isInteractive: Bool
    
    init(
        rating: Binding<Int>,
        maxRating: Int = 5,
        starSize: CGFloat = 32,
        isInteractive: Bool = true
    ) {
        self._rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.isInteractive = isInteractive
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
                    .scaleEffect(star <= rating ? 1.0 : 0.9)
                    .onTapGesture {
                        guard isInteractive else { return }
                        withAnimation(.easeInOut(duration: 0.15)) {
                            rating = star
                        }
                        HapticManager.shared.selection()
                    }
            }
        }
    }
}

/// 唯讀版星級顯示
struct StarRatingDisplay: View {
    let rating: Int
    let maxRating: Int
    let starSize: CGFloat
    
    init(rating: Int, maxRating: Int = 5, starSize: CGFloat = 16) {
        self.rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
            }
        }
    }
}

#Preview("Interactive") {
    @Previewable @State var rating = 3
    StarRatingView(rating: $rating)
}

#Preview("Display Only") {
    StarRatingDisplay(rating: 4)
}
