import SwiftUI
import WidgetKit
import GitStreakKit

/// Small widget: the current streak, the last 7 days and one status line
/// (at risk today, done today, or a new record).
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
        let today = data.todayContributions
        let status = StreakStatus(streak: streak, longest: data.longestStreak, today: today, now: entry.date)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(status.isAtRisk || streak == 0 ? Color.secondary : accent)
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

            WeekDotsView(days: data.recentDays(count: 7), levels: levels, accent: accent)

            Spacer(minLength: 8)

            statusLine(status)
        }
    }

    @ViewBuilder
    private func statusLine(_ status: StreakStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(status.isAtRisk ? Color.orange : accent)
            Text(status.text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(status.isAtRisk ? Color.primary : Color.secondary)
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

// MARK: - Last 7 days
// A streak only cares whether a day had a contribution, so every such day uses the full accent.

private struct WeekDotsView: View {
    let days: [ContributionDay]
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
        let todayString = StreakCalculator.todayDateString()
        HStack(spacing: 0) {
            ForEach(days) { day in
                VStack(spacing: 3) {
                    dot(for: day, isToday: day.date == todayString)
                    Text(letter(for: day.date))
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func dot(for day: ContributionDay, isToday: Bool) -> some View {
        let size: CGFloat = 11
        if day.contributionCount > 0 {
            Circle()
                .fill(accent)
                .frame(width: size, height: size)
        } else if isToday {
            // Today isn't over yet: an open ring, not a missed day.
            Circle()
                .strokeBorder(accent, lineWidth: 1.5)
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
