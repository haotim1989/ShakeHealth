import SwiftUI

// MARK: - 飲品分類圖示元件

/// 統一風格的飲品分類圖示
/// 所有圖示均使用 SwiftUI Path 繪製，確保風格一致、非寫實
struct CategoryIconView: View {
    let category: DrinkCategory
    let size: CGFloat
    
    /// 是否使用分類專屬顏色（false 時使用外部 foregroundColor）
    var useThemeColor: Bool = true
    
    init(category: DrinkCategory, size: CGFloat = 28, useThemeColor: Bool = true) {
        self.category = category
        self.size = size
        self.useThemeColor = useThemeColor
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            drawIcon(context: context, size: s)
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - 繪製入口
    
    private func drawIcon(context: GraphicsContext, size: CGFloat) {
        switch category {
        case .milkTea:
            drawBubbleTeaCup(context: context, size: size)
        case .pureTea:
            drawTeaLeaf(context: context, size: size)
        case .fruitTea:
            drawOrange(context: context, size: size)
        case .coffee:
            drawCoffeeCup(context: context, size: size)
        case .fresh:
            drawCowHead(context: context, size: size)
        case .special:
            drawSpecialMix(context: context, size: size)
        }
    }
    
    // MARK: - 1. 奶茶類 — 手搖飲料杯
    
    private func drawBubbleTeaCup(context: GraphicsContext, size: CGFloat) {
        let color = useThemeColor ? Color.teaBrown : Color.primary
        
        // 杯身（梯形）
        var cupPath = Path()
        let cupTop: CGFloat = size * 0.30
        let cupBottom: CGFloat = size * 0.88
        let topLeft: CGFloat = size * 0.22
        let topRight: CGFloat = size * 0.78
        let bottomLeft: CGFloat = size * 0.30
        let bottomRight: CGFloat = size * 0.70
        
        cupPath.move(to: CGPoint(x: topLeft, y: cupTop))
        cupPath.addLine(to: CGPoint(x: topRight, y: cupTop))
        cupPath.addLine(to: CGPoint(x: bottomRight, y: cupBottom))
        cupPath.addLine(to: CGPoint(x: bottomLeft, y: cupBottom))
        cupPath.closeSubpath()
        context.fill(cupPath, with: .color(color.opacity(0.25)))
        context.stroke(cupPath, with: .color(color), lineWidth: size * 0.04)
        
        // 杯蓋（圓頂）
        var lidPath = Path()
        let lidY: CGFloat = cupTop
        let lidHeight: CGFloat = size * 0.08
        lidPath.move(to: CGPoint(x: topLeft - size * 0.03, y: lidY))
        lidPath.addLine(to: CGPoint(x: topRight + size * 0.03, y: lidY))
        lidPath.addLine(to: CGPoint(x: topRight, y: lidY - lidHeight))
        lidPath.addLine(to: CGPoint(x: topLeft, y: lidY - lidHeight))
        lidPath.closeSubpath()
        context.fill(lidPath, with: .color(color))
        
        // 吸管
        var strawPath = Path()
        let strawX: CGFloat = size * 0.55
        strawPath.move(to: CGPoint(x: strawX, y: size * 0.06))
        strawPath.addLine(to: CGPoint(x: strawX - size * 0.06, y: cupTop - lidHeight))
        context.stroke(strawPath, with: .color(color), lineWidth: size * 0.04)
        
        // 珍珠 (3顆)
        let pearlSize: CGFloat = size * 0.065
        let pearlY: CGFloat = size * 0.72
        let pearls: [(CGFloat, CGFloat)] = [
            (size * 0.40, pearlY),
            (size * 0.52, pearlY + size * 0.06),
            (size * 0.60, pearlY - size * 0.02)
        ]
        for (px, py) in pearls {
            let pearlRect = CGRect(x: px - pearlSize, y: py - pearlSize, width: pearlSize * 2, height: pearlSize * 2)
            context.fill(Path(ellipseIn: pearlRect), with: .color(color.opacity(0.7)))
        }
    }
    
    // MARK: - 2. 原茶類 — 茶葉
    
    private func drawTeaLeaf(context: GraphicsContext, size: CGFloat) {
        let color = useThemeColor ? Color.greenTea : Color.primary
        let cx = size * 0.5
        
        // 主葉片
        var leafPath = Path()
        leafPath.move(to: CGPoint(x: cx, y: size * 0.10))
        leafPath.addQuadCurve(
            to: CGPoint(x: cx, y: size * 0.85),
            control: CGPoint(x: size * 0.90, y: size * 0.35)
        )
        leafPath.addQuadCurve(
            to: CGPoint(x: cx, y: size * 0.10),
            control: CGPoint(x: size * 0.10, y: size * 0.35)
        )
        leafPath.closeSubpath()
        context.fill(leafPath, with: .color(color.opacity(0.3)))
        context.stroke(leafPath, with: .color(color), lineWidth: size * 0.035)
        
        // 葉脈（中線）
        var veinPath = Path()
        veinPath.move(to: CGPoint(x: cx, y: size * 0.18))
        veinPath.addLine(to: CGPoint(x: cx, y: size * 0.78))
        context.stroke(veinPath, with: .color(color), lineWidth: size * 0.025)
        
        // 側葉脈
        let veins: [(CGFloat, CGFloat, CGFloat)] = [
            (0.33, 0.40, 0.08),
            (0.45, 0.52, 0.10),
            (0.55, 0.63, 0.08),
        ]
        for (startY, _, offset) in veins {
            var sideVein = Path()
            sideVein.move(to: CGPoint(x: cx, y: size * startY))
            sideVein.addLine(to: CGPoint(x: cx + size * (offset + 0.12), y: size * (startY - 0.06)))
            context.stroke(sideVein, with: .color(color.opacity(0.6)), lineWidth: size * 0.02)
            
            var sideVein2 = Path()
            sideVein2.move(to: CGPoint(x: cx, y: size * startY))
            sideVein2.addLine(to: CGPoint(x: cx - size * (offset + 0.08), y: size * (startY - 0.04)))
            context.stroke(sideVein2, with: .color(color.opacity(0.6)), lineWidth: size * 0.02)
        }
    }
    
    // MARK: - 3. 果茶類 — 橘子
    
    private func drawOrange(context: GraphicsContext, size: CGFloat) {
        let color = useThemeColor ? Color.fruitOrange : Color.primary
        let cx = size * 0.5
        let cy = size * 0.52
        let radius = size * 0.34
        
        // 橘子本體（圓形）
        let orangeRect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: orangeRect), with: .color(color.opacity(0.3)))
        context.stroke(Path(ellipseIn: orangeRect), with: .color(color), lineWidth: size * 0.04)
        
        // 頂部莖 + 葉子
        let stemColor = useThemeColor ? Color.greenTea : Color.primary
        
        // 莖
        var stemPath = Path()
        stemPath.move(to: CGPoint(x: cx, y: cy - radius))
        stemPath.addLine(to: CGPoint(x: cx, y: cy - radius - size * 0.08))
        context.stroke(stemPath, with: .color(stemColor), lineWidth: size * 0.035)
        
        // 小葉子
        var leafPath = Path()
        let leafStart = CGPoint(x: cx + size * 0.02, y: cy - radius - size * 0.06)
        leafPath.move(to: leafStart)
        leafPath.addQuadCurve(
            to: CGPoint(x: cx + size * 0.18, y: cy - radius - size * 0.16),
            control: CGPoint(x: cx + size * 0.16, y: cy - radius - size * 0.03)
        )
        leafPath.addQuadCurve(
            to: leafStart,
            control: CGPoint(x: cx + size * 0.04, y: cy - radius - size * 0.18)
        )
        context.fill(leafPath, with: .color(stemColor.opacity(0.5)))
        context.stroke(leafPath, with: .color(stemColor), lineWidth: size * 0.025)
        
        // 橘子紋理（放射線段）
        let lineCount = 4
        for i in 0..<lineCount {
            let angle = Double(i) * .pi / Double(lineCount) + .pi / 8
            var linePath = Path()
            let innerR = radius * 0.15
            let outerR = radius * 0.7
            linePath.move(to: CGPoint(
                x: cx + innerR * CGFloat(cos(angle)),
                y: cy + innerR * CGFloat(sin(angle))
            ))
            linePath.addLine(to: CGPoint(
                x: cx + outerR * CGFloat(cos(angle)),
                y: cy + outerR * CGFloat(sin(angle))
            ))
            context.stroke(linePath, with: .color(color.opacity(0.3)), lineWidth: size * 0.02)
        }
    }
    
    // MARK: - 4. 咖啡類 — 咖啡杯
    
    private func drawCoffeeCup(context: GraphicsContext, size: CGFloat) {
        let color = useThemeColor ? Color.coffeeBrown : Color.primary
        
        // 杯身（圓角矩形）
        let cupLeft: CGFloat = size * 0.18
        let cupRight: CGFloat = size * 0.68
        let cupTop: CGFloat = size * 0.32
        let cupBottom: CGFloat = size * 0.78
        let cupRect = CGRect(x: cupLeft, y: cupTop, width: cupRight - cupLeft, height: cupBottom - cupTop)
        let cupRR = RoundedRectangle(cornerRadius: size * 0.06).path(in: cupRect)
        context.fill(cupRR, with: .color(color.opacity(0.25)))
        context.stroke(cupRR, with: .color(color), lineWidth: size * 0.04)
        
        // 把手（C 形弧）
        var handlePath = Path()
        handlePath.addArc(
            center: CGPoint(x: cupRight, y: (cupTop + cupBottom) / 2),
            radius: size * 0.12,
            startAngle: .degrees(-60),
            endAngle: .degrees(60),
            clockwise: false
        )
        context.stroke(handlePath, with: .color(color), lineWidth: size * 0.04)
        
        // 碟子
        var saucerPath = Path()
        let saucerY = cupBottom + size * 0.04
        saucerPath.addEllipse(in: CGRect(
            x: size * 0.12,
            y: saucerY,
            width: size * 0.65,
            height: size * 0.10
        ))
        context.fill(saucerPath, with: .color(color.opacity(0.2)))
        context.stroke(saucerPath, with: .color(color), lineWidth: size * 0.03)
        
        // 蒸氣（3條波浪線）
        let steamXs: [CGFloat] = [size * 0.33, size * 0.43, size * 0.53]
        for (i, sx) in steamXs.enumerated() {
            var steamPath = Path()
            let steamBottom = cupTop - size * 0.04
            let steamTop = size * 0.10
            let waveAmp: CGFloat = size * 0.04
            let offset: CGFloat = i % 2 == 0 ? waveAmp : -waveAmp
            
            steamPath.move(to: CGPoint(x: sx, y: steamBottom))
            steamPath.addCurve(
                to: CGPoint(x: sx, y: steamTop),
                control1: CGPoint(x: sx + offset, y: steamBottom - (steamBottom - steamTop) * 0.33),
                control2: CGPoint(x: sx - offset, y: steamBottom - (steamBottom - steamTop) * 0.66)
            )
            context.stroke(steamPath, with: .color(color.opacity(0.35)), lineWidth: size * 0.025)
        }
    }
    
    // MARK: - 5. 鮮奶系列 — 可愛乳牛頭
    
    private func drawCowHead(context: GraphicsContext, size: CGFloat) {
        let brownColor = useThemeColor ? Color.coffeeBrown : Color.primary
        let whiteColor = Color.white
        let cx = size * 0.5
        let cy = size * 0.52
        let headRadius = size * 0.30
        
        // 耳朵（左右橢圓）
        let earWidth: CGFloat = size * 0.14
        let earHeight: CGFloat = size * 0.10
        let earY = cy - headRadius * 0.6
        
        // 左耳
        let leftEarRect = CGRect(x: cx - headRadius - earWidth * 0.5, y: earY - earHeight * 0.5, width: earWidth, height: earHeight)
        context.fill(Path(ellipseIn: leftEarRect), with: .color(brownColor.opacity(0.5)))
        context.stroke(Path(ellipseIn: leftEarRect), with: .color(brownColor), lineWidth: size * 0.025)
        
        // 右耳
        let rightEarRect = CGRect(x: cx + headRadius - earWidth * 0.5, y: earY - earHeight * 0.5, width: earWidth, height: earHeight)
        context.fill(Path(ellipseIn: rightEarRect), with: .color(brownColor.opacity(0.5)))
        context.stroke(Path(ellipseIn: rightEarRect), with: .color(brownColor), lineWidth: size * 0.025)
        
        // 頭部（圓形）
        let headRect = CGRect(x: cx - headRadius, y: cy - headRadius, width: headRadius * 2, height: headRadius * 2)
        context.fill(Path(ellipseIn: headRect), with: .color(whiteColor))
        context.stroke(Path(ellipseIn: headRect), with: .color(brownColor), lineWidth: size * 0.035)
        
        // 牛斑點（左上 + 右）
        var spot1 = Path()
        spot1.addEllipse(in: CGRect(x: cx - headRadius * 0.7, y: cy - headRadius * 0.5, width: size * 0.14, height: size * 0.12))
        context.fill(spot1, with: .color(brownColor.opacity(0.45)))
        
        var spot2 = Path()
        spot2.addEllipse(in: CGRect(x: cx + headRadius * 0.2, y: cy - headRadius * 0.3, width: size * 0.12, height: size * 0.10))
        context.fill(spot2, with: .color(brownColor.opacity(0.45)))
        
        // 眼睛（兩個小圓）
        let eyeSize: CGFloat = size * 0.055
        let eyeY = cy - size * 0.03
        let eyeSpacing = size * 0.13
        
        let leftEye = CGRect(x: cx - eyeSpacing - eyeSize, y: eyeY - eyeSize, width: eyeSize * 2, height: eyeSize * 2)
        context.fill(Path(ellipseIn: leftEye), with: .color(brownColor))
        
        let rightEye = CGRect(x: cx + eyeSpacing - eyeSize, y: eyeY - eyeSize, width: eyeSize * 2, height: eyeSize * 2)
        context.fill(Path(ellipseIn: rightEye), with: .color(brownColor))
        
        // 鼻孔（橢圓口鼻區）
        let snoutWidth: CGFloat = size * 0.20
        let snoutHeight: CGFloat = size * 0.12
        let snoutY = cy + size * 0.12
        let snoutRect = CGRect(x: cx - snoutWidth / 2, y: snoutY, width: snoutWidth, height: snoutHeight)
        context.fill(Path(ellipseIn: snoutRect), with: .color(brownColor.opacity(0.15)))
        context.stroke(Path(ellipseIn: snoutRect), with: .color(brownColor.opacity(0.4)), lineWidth: size * 0.02)
        
        // 兩個鼻孔小點
        let nostrilSize: CGFloat = size * 0.025
        let nostrilY = snoutY + snoutHeight * 0.45
        let leftNostril = CGRect(x: cx - size * 0.045 - nostrilSize, y: nostrilY - nostrilSize, width: nostrilSize * 2, height: nostrilSize * 2)
        context.fill(Path(ellipseIn: leftNostril), with: .color(brownColor.opacity(0.6)))
        
        let rightNostril = CGRect(x: cx + size * 0.045 - nostrilSize, y: nostrilY - nostrilSize, width: nostrilSize * 2, height: nostrilSize * 2)
        context.fill(Path(ellipseIn: rightNostril), with: .color(brownColor.opacity(0.6)))
    }
    
    // MARK: - 6. 特調類 — 星星特調
    
    private func drawSpecialMix(context: GraphicsContext, size: CGFloat) {
        let color = useThemeColor ? Color.specialBlue : Color.primary
        
        // 三顆大小不同的星星
        drawStar(context: context, center: CGPoint(x: size * 0.38, y: size * 0.32), radius: size * 0.18, color: color.opacity(0.4))
        drawStar(context: context, center: CGPoint(x: size * 0.65, y: size * 0.50), radius: size * 0.22, color: color.opacity(0.3))
        drawStar(context: context, center: CGPoint(x: size * 0.40, y: size * 0.68), radius: size * 0.14, color: color.opacity(0.35))
        
        // 外框星星
        drawStar(context: context, center: CGPoint(x: size * 0.38, y: size * 0.32), radius: size * 0.18, color: color, fill: false)
        drawStar(context: context, center: CGPoint(x: size * 0.65, y: size * 0.50), radius: size * 0.22, color: color, fill: false)
        drawStar(context: context, center: CGPoint(x: size * 0.40, y: size * 0.68), radius: size * 0.14, color: color, fill: false)
    }
    
    // MARK: - Helper: 繪製星星
    
    private func drawStar(context: GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, fill: Bool = true) {
        var path = Path()
        let points = 4
        let innerRadius = radius * 0.4
        
        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let r = i % 2 == 0 ? radius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(Foundation.cos(angle)) * r,
                y: center.y + CGFloat(Foundation.sin(angle)) * r
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        
        if fill {
            context.fill(path, with: .color(color))
        } else {
            context.stroke(path, with: .color(color), lineWidth: radius * 0.15)
        }
    }
}

// MARK: - Preview

#Preview("All Categories") {
    VStack(spacing: 24) {
        ForEach(DrinkCategory.allCases) { category in
            HStack(spacing: 16) {
                // 小尺寸 (列表用)
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(category.themeColor.opacity(0.12))
                        .frame(width: 50, height: 50)
                    
                    CategoryIconView(category: category, size: 30)
                }
                
                // 大尺寸 (結果卡片用)
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    CategoryIconView(category: category, size: 64)
                }
                .frame(width: 100, height: 100)
                
                Text(category.rawValue)
                    .font(.headline)
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}
