import SwiftUI

public struct ContributionGridView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let weeks: [ContributionWeek]
    public let theme: ThemeColors
    public let maxWeeks: Int
    public let cellSize: CGFloat
    public let cellSpacing: CGFloat
    public let columnSpacing: CGFloat?
    public let rowSpacing: CGFloat?
    public let cornerRadius: CGFloat?
    public let showTooltips: Bool

    public init(
        weeks: [ContributionWeek],
        theme: ThemeColors = ThemeRegistry.defaultTheme,
        maxWeeks: Int = 13,
        cellSize: CGFloat = GSSpacing.gridCellSize,
        cellSpacing: CGFloat = GSSpacing.gridCellSpacing,
        columnSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        showTooltips: Bool = false
    ) {
        self.weeks = weeks
        self.theme = theme
        self.maxWeeks = maxWeeks
        self.cellSize = cellSize
        self.cellSpacing = cellSpacing
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
        self.cornerRadius = cornerRadius
        self.showTooltips = showTooltips
    }

    public var body: some View {
        let displayWeeks = Array(weeks.suffix(maxWeeks))
        let colSpacing = columnSpacing ?? cellSpacing
        let rSpacing = rowSpacing ?? cellSpacing

        HStack(spacing: colSpacing) {
            ForEach(Array(displayWeeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: rSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if dayIndex < week.contributionDays.count {
                            let day = week.contributionDays[dayIndex]
                            cellView(for: day)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(for day: ContributionDay) -> some View {
        let cellColor = theme.color(for: day.level, colorScheme: colorScheme)
        let radius = cornerRadius ?? max(1.0, cellSize * 0.2)
        let rect = RoundedRectangle(cornerRadius: radius)
            .fill(cellColor)
            .frame(width: cellSize, height: cellSize)

        if showTooltips {
            rect.help("\(day.contributionCount) contributions on \(day.date)")
        } else {
            rect
        }
    }
}
