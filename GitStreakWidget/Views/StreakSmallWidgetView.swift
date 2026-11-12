import SwiftUI
import WidgetKit
import GitStreakKit

/// Small widget: the current streak and this week's days, Sunday first.
struct StreakSmallWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    var entry: GitStreakEntry

    private var widgetGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(hex: "#242426"), Color(hex: "#141416")]
                : [Color.white, Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// The theme's levels from "none" to "very high", in widget colours.
    private var levels: [Color] {
        entry.theme.allColors(for: colorScheme, isWidget: true)
    }

    private var accent: Color { levels.last ?? .green }

    var body: some View {
        Group {
            switch entry.state {
            case .loaded:
                if let data = entry.contributionData {
                    content(data)
                } else {
                    message("Open app to sync", systemImage: "arrow.clockwise")
                }
            case .noUser:
                message("Add GitHub Account", systemImage: "person.crop.circle.badge.plus")
            case .noData:
                message("Open app to sync", systemImage: "arrow.clockwise")
            case .error(let text):
                message(text, systemImage: "exclamationmark.triangle")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { widgetGradient }
    }

    // MARK: - Content

    private func content(_ data: ContributionData) -> some View {
        let streak = data.currentStreak
        let flameIsGrey = streak == 0 || data.todayContributions == 0

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(flameIsGrey ? Color.secondary : accent)
                Text("STREAK")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Text("\(streak)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(streak == 1 ? "day" : "days")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            WeekDotsView(data: data, now: entry.date, levels: levels, accent: accent)

            if streak == 0 {
                Spacer(minLength: 8)
                startStreakLine
            }
        }
    }

    private var startStreakLine: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(accent)
            Text("Start a streak today")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func message(_ text: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - This week
// Sunday to Saturday. A streak only cares whether a day had a contribution,
// so every such day uses the full accent.

private struct WeekDotsView: View {
    let data: ContributionData
    let now: Date
    let levels: [Color]
    let accent: Color

    private static let parser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let weekdayLetter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter
    }()

    var body: some View {
        let today = StreakCalculator.todayDateString()
        let counts = Dictionary(data.allDays.map { ($0.date, $0.contributionCount) }, uniquingKeysWith: max)
        HStack(spacing: 0) {
            ForEach(StreakWeek.dates(containing: now), id: \.self) { date in
                VStack(spacing: 3) {
                    dot(count: counts[date] ?? 0, isToday: date == today, isFuture: date > today)
                    Text(letter(for: date))
                        .font(.system(size: 8, weight: date == today ? .bold : .medium))
                        .foregroundStyle(date == today ? Color.primary : Color.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func dot(count: Int, isToday: Bool, isFuture: Bool) -> some View {
        let size: CGFloat = 11
        if count > 0 {
            Circle()
                .fill(accent)
                .frame(width: size, height: size)
        } else if isToday {
            // Today isn't over yet: an open ring, not a missed day.
            Circle()
                .strokeBorder(accent, lineWidth: 1.5)
                .frame(width: size, height: size)
        } else if isFuture {
            // Still to come this week.
            Circle()
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                .frame(width: size, height: size)
        } else {
            Circle()
                .fill(levels.first ?? Color.secondary.opacity(0.2))
                .frame(width: size, height: size)
        }
    }

    private func letter(for date: String) -> String {
        guard let parsed = Self.parser.date(from: date) else { return "" }
        return Self.weekdayLetter.string(from: parsed)
    }
}
