import SwiftUI
import WidgetKit
import GitStreakKit

public struct ThemePickerView: View {
    @Binding var selectedThemeID: String
    let onThemeChanged: (String) -> Void

    public init(selectedThemeID: Binding<String>, onThemeChanged: @escaping (String) -> Void) {
        self._selectedThemeID = selectedThemeID
        self.onThemeChanged = onThemeChanged
    }

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ThemeRegistry.allThemes, id: \.id) { theme in
                ThemeSwatchGridItem(
                    theme: theme,
                    isSelected: selectedThemeID == theme.id
                )
                .onTapGesture {
                    selectedThemeID = theme.id
                    UserPreferences.shared.selectedThemeID = theme.id
                    onThemeChanged(theme.id)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
    }
}

struct ThemeSwatchGridItem: View {
    @Environment(\.colorScheme) private var colorScheme
    let theme: ThemeColors
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            let colors = theme.allColors(for: colorScheme)
            HStack(spacing: 4) {
                ForEach(colors.indices, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colors[idx])
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)

            HStack {
                Text(theme.name)
                    .font(GSTypography.monoCaption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11))
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(isHovered ? 0.9 : 0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.orange : Color.white.opacity(isHovered ? 0.15 : 0.06), lineWidth: isSelected ? 1.5 : 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
    }
}
