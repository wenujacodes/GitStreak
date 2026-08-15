import SwiftUI

// Uses ContributionDay and ContributionWeek from GitHub/Models/

public struct ContributionGridView: View {
    public let weeks: [ContributionWeek]
    public let theme: ThemeColors
    public let maxWeeks: Int
    public let cellSize: CGFloat
    public let cellSpacing: CGFloat
    
    public init(
        weeks: [ContributionWeek],
        theme: ThemeColors = ThemeRegistry.defaultTheme,
        maxWeeks: Int = 13,
        cellSize: CGFloat = GSSpacing.gridCellSize,
        cellSpacing: CGFloat = GSSpacing.gridCellSpacing
    ) {
        self.weeks = weeks
        self.theme = theme
        self.maxWeeks = maxWeeks
        self.cellSize = cellSize
        self.cellSpacing = cellSpacing
    }
    
    public var body: some View {
        let displayWeeks = Array(weeks.suffix(maxWeeks))
        
        HStack(spacing: cellSpacing) {
            ForEach(Array(displayWeeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if dayIndex < week.contributionDays.count {
                            let day = week.contributionDays[dayIndex]
                            RoundedRectangle(cornerRadius: GSSpacing.gridCellCornerRadius)
                                .fill(theme.color(for: day.level))
                                .frame(width: cellSize, height: cellSize)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
}
