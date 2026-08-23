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
    public let showMonthHeaders: Bool
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
        showMonthHeaders: Bool = false,
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
        self.showMonthHeaders = showMonthHeaders
        self.showTooltips = showTooltips
    }

    public var body: some View {
        let displayWeeks = Array(weeks.suffix(maxWeeks))
        let colSpacing = columnSpacing ?? cellSpacing
        let rSpacing = rowSpacing ?? cellSpacing

        HStack(spacing: colSpacing) {
            ForEach(Array(displayWeeks.enumerated()), id: \.offset) { weekIdx, week in
                ContributionWeekColumnView(
                    week: week,
                    monthLabel: monthLabel(for: weekIdx, in: displayWeeks),
                    rSpacing: rSpacing,
                    cellSize: cellSize,
                    theme: theme,
                    cornerRadius: cornerRadius,
                    showMonthHeaders: showMonthHeaders,
                    showTooltips: showTooltips,
                    colorScheme: colorScheme
                )
            }
        }
    }

    private func monthLabel(for weekIndex: Int, in displayWeeks: [ContributionWeek]) -> String? {
        guard weekIndex < displayWeeks.count, let firstDayStr = displayWeeks[weekIndex].contributionDays.first?.date else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: firstDayStr) else {
            return nil
        }

        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)

        if weekIndex == 0 {
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            return monthFormatter.string(from: date)
        }

        if let prevFirstDayStr = displayWeeks[weekIndex - 1].contributionDays.first?.date,
           let prevDate = formatter.date(from: prevFirstDayStr) {
            let prevMonth = calendar.component(.month, from: prevDate)
            if month != prevMonth {
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMM"
                return monthFormatter.string(from: date)
            }
        }

        return nil
    }
}

private struct ContributionWeekColumnView: View {
    let week: ContributionWeek
    let monthLabel: String?
    let rSpacing: CGFloat
    let cellSize: CGFloat
    let theme: ThemeColors
    let cornerRadius: CGFloat?
    let showMonthHeaders: Bool
    let showTooltips: Bool
    let colorScheme: ColorScheme

    @State private var isColumnHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: rSpacing) {
            if showMonthHeaders {
                Text(monthLabel ?? "")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(height: 14, alignment: .leading)
                    .fixedSize()
            }

            ForEach(0..<7, id: \.self) { dayIndex in
                if dayIndex < week.contributionDays.count {
                    let day = week.contributionDays[dayIndex]
                    let cellColor = theme.color(for: day.level, colorScheme: colorScheme)
                    let radius = cornerRadius ?? max(1.0, cellSize * 0.2)
                    let strokeColor = colorScheme == .dark
                        ? Color.white.opacity(0.07)
                        : Color.black.opacity(0.08)

                    ContributionGridCellView(
                        day: day,
                        cellColor: cellColor,
                        radius: radius,
                        strokeColor: strokeColor,
                        cellSize: cellSize,
                        showTooltips: showTooltips
                    )
                } else {
                    Color.clear
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
        .zIndex(isColumnHovered ? 1000 : 1)
        .onHover { hovering in
            isColumnHovered = hovering
        }
    }
}

private struct ContributionGridCellView: View {
    let day: ContributionDay
    let cellColor: Color
    let radius: CGFloat
    let strokeColor: Color
    let cellSize: CGFloat
    let showTooltips: Bool

    @State private var isHovered = false

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(cellColor)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(isHovered ? Color.white.opacity(0.85) : strokeColor, lineWidth: isHovered ? 1.2 : 0.5)
            )
            .scaleEffect(isHovered ? 1.3 : 1.0)
            .shadow(color: isHovered ? Color.black.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 2)
            .overlay(alignment: .top) {
                if isHovered && showTooltips {
                    VStack(spacing: 1) {
                        Text("\(day.contributionCount) contributions")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        Text(day.date)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#1A1D24"))
                            .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .offset(y: -36)
                    .fixedSize()
                    .allowsHitTesting(false)
                }
            }
            .zIndex(isHovered ? 1000 : 1)
            .animation(.easeOut(duration: 0.1), value: isHovered)
            .frame(width: cellSize, height: cellSize)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
