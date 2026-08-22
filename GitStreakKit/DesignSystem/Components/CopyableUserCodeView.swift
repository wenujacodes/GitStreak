import SwiftUI
import AppKit

public struct CopyableUserCodeView: View {
    public let userCode: String
    public var fontSize: CGFloat
    public var paddingVertical: CGFloat
    public var paddingHorizontal: CGFloat
    public var cornerRadius: CGFloat
    
    @State private var isCopied = false
    
    public init(
        userCode: String,
        fontSize: CGFloat = 28,
        paddingVertical: CGFloat = 8,
        paddingHorizontal: CGFloat = 16,
        cornerRadius: CGFloat = 8
    ) {
        self.userCode = userCode
        self.fontSize = fontSize
        self.paddingVertical = paddingVertical
        self.paddingHorizontal = paddingHorizontal
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            Text(userCode)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            
            Button(action: copyToClipboard) {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: max(12, fontSize * 0.55), weight: .medium))
                    .foregroundColor(isCopied ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .help("Copy code to clipboard")
        }
        .padding(.horizontal, paddingHorizontal)
        .padding(.vertical, paddingVertical)
        .background(Color.primary.opacity(0.08))
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isCopied ? Color.green.opacity(0.5) : Color.primary.opacity(0.15), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            copyToClipboard()
        }
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(userCode, forType: .string)
        withAnimation(.easeInOut(duration: 0.15)) {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isCopied = false
            }
        }
    }
}
