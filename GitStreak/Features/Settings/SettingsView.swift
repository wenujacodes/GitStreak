import SwiftUI
import GitStreakKit

struct SettingsView: View {
    @State private var username: String = UserPreferences.shared.username ?? ""
    @State private var token: String = ""
    @State private var showingClearConfirmation = false
    @State private var saveStatusMessage: String?
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 280)
        .padding()
        .onAppear {
            loadToken()
        }
    }
    
    private var generalTab: some View {
        Form {
            Section {
                TextField("GitHub Username:", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: username) { _, newValue in
                        UserPreferences.shared.username = newValue.trimmingCharacters(in: .whitespaces)
                        SharedDataStore.shared.notifyWidgetToRefresh()
                    }
                
                SecureField("Personal Access Token:", text: $token)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    if let msg = saveStatusMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(msg.contains("Failed") ? .red : .green)
                    }
                    
                    Spacer()
                    
                    Button("Save Token") {
                        saveToken()
                    }
                    .disabled(token.isEmpty || token == "••••••••••••••••")
                }
            } footer: {
                Text("Requires a GitHub Personal Access Token (Classic) with 'repo' scope to include private contributions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.orange)
            
            VStack(spacing: 2) {
                Text("GitStreak")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Version 1.0.0 (Build 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("GitStreak keeps all your data strictly on your Mac. We never send your tokens or contributions to any third-party server.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            Text("© 2026 Wenuja Liyanamana")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Reset & Clear All Data", role: .destructive) {
                showingClearConfirmation = true
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .confirmationDialog("Are you sure you want to clear all data?", isPresented: $showingClearConfirmation) {
                Button("Clear Everything", role: .destructive) {
                    clearData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove your cached contribution history, stored GitHub credentials, and reset the app.")
            }
        }
        .padding()
    }
    
    private func loadToken() {
        if KeychainService.load(forKey: "github_pat") != nil {
            token = "••••••••••••••••"
        }
    }
    
    private func saveToken() {
        let cleanToken = token.trimmingCharacters(in: .whitespaces)
        do {
            try KeychainService.save(token: cleanToken, forKey: "github_pat")
            SharedDataStore.shared.notifyWidgetToRefresh()
            saveStatusMessage = "Token saved successfully."
            token = "••••••••••••••••"
        } catch {
            saveStatusMessage = "Failed to update token: \(error.localizedDescription)"
        }
    }
    
    private func clearData() {
        try? SharedDataStore.shared.clearAllData()
        NSApplication.shared.terminate(nil)
    }
}
