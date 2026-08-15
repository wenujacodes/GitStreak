import SwiftUI
import GitStreakKit

public struct ThemePickerView: View {
    @Binding var selectedThemeID: String
    let onThemeChanged: (String) -> Void
    
    public init(selectedThemeID: Binding<String>, onThemeChanged: @escaping (String) -> Void) {
        self._selectedThemeID = selectedThemeID
        self.onThemeChanged = onThemeChanged
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 16)
    ]
    
    public var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(ThemeRegistry.allThemes, id: \.id) { theme in
                ThemeSwatchGridItem(
                    theme: theme,
                    isSelected: selectedThemeID == theme.id
                )
                .onTapGesture {
                    selectedThemeID = theme.id
                    onThemeChanged(theme.id)
                }
            }
        }
    }
}

struct ThemeSwatchGridItem: View {
    let theme: ThemeColors
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(theme.allColors.indices, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.allColors[idx])
                        .frame(width: 16, height: 16)
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .background(Circle().fill(Color.white))
                        .offset(x: 6, y: -6)
                }
            }
            
            Text(theme.name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .contentShape(Rectangle())
    }
}
