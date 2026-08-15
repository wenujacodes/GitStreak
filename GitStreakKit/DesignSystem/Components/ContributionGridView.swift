import SwiftUI

public struct ContributionGridView: View {
    public let weeks: [ContributionWeek]
    public let theme: ThemeColors
    public let maxWeeks: Int
    public let cellSize: CGFloat
    public let cellSpacing: CGFloat
    public let showTooltips: Bool
    
    public init(
        weeks: [ContributionWeek],
        theme: ThemeColors = ThemeRegistry.defaultTheme,
        maxWeeks: Int = 13,
        cellSize: CGFloat = GSSpacing.gridCellSize,
        cellSpacing: CGFloat = GSSpacing.gridCellSpacing,
        showTooltips: Bool = false
    ) {
        self.weeks = weeks
        self.theme = theme
        self.maxWeeks = maxWeeks
        self.cellSize = cellSize
        self.cellSpacing = cellSpacing
        self.showTooltips = showTooltips
    }
    
    public var body: some View {
        let displayWeeks = Array(weeks.suffix(maxWeeks))
        
        HStack(spacing: cellSpacing) {
            ForEach(Array(displayWeeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: cellSpacing) {
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
        let rect = RoundedRectangle(cornerRadius: max(2, cellSize * 0.2))
            .fill(theme.color(for: day.level))
            .frame(width: cellSize, height: cellSize)
        
        if showTooltips {
            rect.help("\(day.contributionCount) contributions on \(day.date)")
        } else {
            rect
        }
    }
}
