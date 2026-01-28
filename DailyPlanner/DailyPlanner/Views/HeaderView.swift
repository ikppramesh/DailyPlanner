import SwiftUI
import UniformTypeIdentifiers

extension UIDevice {
    var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}

struct HeaderView: View {
    @EnvironmentObject var store: PlannerStore
    @ObservedObject var googleService: GoogleCalendarService
    @ObservedObject var storageService: DataStorageService
    @State private var showSavedAlert = false
    @State private var alertMessage = ""
    @State private var showSyncAlert = false
    @State private var syncMessage = ""
    @State private var showAccountSettings = false
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var exportURL: URL?

    var body: some View {
        HStack {
            // Day of week
            Text(store.dayOfWeek)
                .font(.system(size: UIDevice.current.isIPad ? 33.52 : 13.68, weight: .medium))
                .foregroundColor(.cyan)

            Spacer()

            // Date - Month and Day
            Text("\(store.selectedDay) \(store.monthName)")
                .font(.system(size: UIDevice.current.isIPad ? 38.81 : 15.84, weight: .bold))
                .foregroundColor(.cyan)

            Spacer()

            // Settings button
            Button(action: {
                showAccountSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.system(size: UIDevice.current.isIPad ? 24.70 : 10.08))
                    .foregroundColor(.cyan)
            }
            .padding(.trailing, 8)

            // Year
            Text("\(String(store.selectedYear))")
                .font(.system(size: UIDevice.current.isIPad ? 33.52 : 13.68, weight: .medium))
                .foregroundColor(.cyan)
            
            // Export button - download all data
            Button(action: {
                exportAllData()
            }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: UIDevice.current.isIPad ? 24.70 : 10.08))
                    .foregroundColor(.cyan)
            }
            .padding(.leading, 8)
            
            // Import button - upload data file
            Button(action: {
                showImportPicker = true
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: UIDevice.current.isIPad ? 24.70 : 10.08))
                    .foregroundColor(.cyan)
            }
            .padding(.leading, 8)
            
            // Screenshot button - saves to Photos
            Button(action: {
                takeScreenshot()
            }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: UIDevice.current.isIPad ? 24.70 : 10.08))
                    .foregroundColor(.cyan)
            }
            .padding(.leading, 8)
            .alert("Screenshot", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }

            // Drawing mode toggle
            Button(action: {
                store.isDrawingMode.toggle()
            }) {
                Image(systemName: store.isDrawingMode ? "pencil.circle.fill" : "pencil.circle")
                    .font(.system(size: UIDevice.current.isIPad ? 24.70 : 10.08))
                    .foregroundColor(store.isDrawingMode ? .orange : .gray)
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal, UIDevice.current.isIPad ? 24 : 16)
        .padding(.vertical, UIDevice.current.isIPad ? 16 : 10)
        .background(Color.black)
        .sheet(isPresented: $showAccountSettings) {
            AccountSettingsView(googleService: googleService, storageService: storageService)
                .environmentObject(store)
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.folder, .json]) { result in
            handleImport(result: result)
        }
    }
    
    func takeScreenshot() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
            alertMessage = "Could not capture screenshot"
            showSavedAlert = true
            return
        }
        
        // Force layout
        window.layoutIfNeeded()
        
        // Capture using layer rendering
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds, format: format)
        let image = renderer.image { ctx in
            window.layer.render(in: ctx.cgContext)
        }
        
        // Save to Photos
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        alertMessage = "Screenshot saved to Photos!"
        showSavedAlert = true
    }
    
    func exportAllData() {
        // Get all saved dates
        let dates = storageService.savedDates()
        
        guard !dates.isEmpty else {
            alertMessage = "No data to export"
            showSavedAlert = true
            return
        }
        
        // Create export directory in Documents for easy access
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportDir = documentsDir.appendingPathComponent("DailyPlannerBackup_\(Date().timeIntervalSince1970)")
        try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        
        // Copy all plan files
        var exportedCount = 0
        for date in dates {
            if let plan = storageService.load(for: date) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let filename = "\(formatter.string(from: date)).json"
                let fileURL = exportDir.appendingPathComponent(filename)
                
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                if let data = try? encoder.encode(plan) {
                    try? data.write(to: fileURL)
                    exportedCount += 1
                }
            }
        }
        
        exportURL = exportDir
        
        // Show share sheet with the folder
        let activityVC = UIActivityViewController(activityItems: [exportDir], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // For iPad, set source view
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
        
        alertMessage = "✓ Sharing \(exportedCount) day(s)\n\nTip: Use AirDrop to send to your other iPad"
        showSavedAlert = true
    }
    
    func handleImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            importData(from: url)
        case .failure(let error):
            alertMessage = "Import failed: \(error.localizedDescription)"
            showSavedAlert = true
        }
    }
    
    func importData(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            alertMessage = "Cannot access file"
            showSavedAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            var jsonFiles: [URL] = []
            var isDirectory: ObjCBool = false
            
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // It's a folder, get all JSON files
                    jsonFiles = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                        .filter { $0.pathExtension == "json" }
                } else if url.pathExtension == "json" {
                    // It's a single JSON file
                    jsonFiles = [url]
                }
            }
            
            guard !jsonFiles.isEmpty else {
                alertMessage = "No JSON files found"
                showSavedAlert = true
                return
            }
            
            // Import all plans
            var importedCount = 0
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            for fileURL in jsonFiles {
                let data = try Data(contentsOf: fileURL)
                if let plan = try? decoder.decode(DayPlan.self, from: data) {
                    storageService.save(plan: plan, for: plan.date)
                    importedCount += 1
                }
            }
            
            // Reload current plan
            store.loadPlan(for: store.selectedDate)
            
            alertMessage = "✓ Imported \(importedCount) day(s)"
            showSavedAlert = true
            
        } catch {
            alertMessage = "Import failed: \(error.localizedDescription)"
            showSavedAlert = true
        }
    }
}

#Preview {
    HeaderView(
        googleService: GoogleCalendarService(),
        storageService: DataStorageService()
    )
        .environmentObject(PlannerStore())
        .preferredColorScheme(.dark)
}

// MARK: - Account Settings View
struct AccountSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: PlannerStore
    @ObservedObject var googleService: GoogleCalendarService
    @ObservedObject var storageService: DataStorageService
    @State private var showSyncAlert = false
    @State private var syncMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(googleService.isAuthenticated ? .blue : .gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(googleService.isAuthenticated ? "Google Account" : "Not Connected")
                                .font(.headline)
                            
                            if googleService.isAuthenticated {
                                Text("Signed in")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Sign in to enable sync")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                        
                        if googleService.isAuthenticated {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Account")
                }
                
                // Sign In / Out Section
                Section {
                    if googleService.isAuthenticated {
                        Button(action: {
                            googleService.signOut()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Button(action: {
                            googleService.signIn()
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("Sign in with Google")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Authentication")
                } footer: {
                    if !googleService.isAuthenticated {
                        Text("Sign in with your Google account to enable Calendar integration and Drive sync across all your devices.")
                    }
                }
                
                // Sync Section
                if googleService.isAuthenticated {
                    Section {
                        // Manual Sync Button
                        Button(action: {
                            performSync()
                        }) {
                            HStack {
                                if storageService.isSyncing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Syncing...")
                                        .padding(.leading, 8)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Sync Now")
                                        .padding(.leading, 8)
                                }
                                Spacer()
                            }
                        }
                        .disabled(storageService.isSyncing)
                        
                        // Last Sync Time
                        if let lastSync = storageService.lastSyncDate {
                            HStack {
                                Text("Last Synced")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatDate(lastSync))
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                        
                        // Sync Status
                        if let error = storageService.syncError {
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading) {
                                    Text("Sync Error")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Google Drive Sync")
                    } footer: {
                        Text("Sync your daily plans across all devices using Google Drive. Tap 'Sync Now' to upload your local data and download any changes from other devices.")
                    }
                }
                
                // Features Section
                Section {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Calendar Integration")
                                .font(.subheadline)
                            Text(googleService.isAuthenticated ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(googleService.isAuthenticated ? .green : .secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cross-Device Sync")
                                .font(.subheadline)
                            Text(googleService.isAuthenticated ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(googleService.isAuthenticated ? .green : .secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hourly Notifications")
                                .font(.subheadline)
                            Text("Enabled")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Features")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1.0")
                    }
                    
                    HStack {
                        Text("Build")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("2026.01.28")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sync Status", isPresented: $showSyncAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncMessage)
            }
        }
    }
    
    private func performSync() {
        googleService.getAccessToken { token in
            guard let token = token else {
                DispatchQueue.main.async {
                    syncMessage = "Your Google session has expired.\n\nPlease sign out and sign in again to refresh your credentials."
                    showSyncAlert = true
                }
                return
            }
            
            // Upload local data to Drive
            storageService.syncToGoogleDrive(accessToken: token) { success, error in
                if !success {
                    DispatchQueue.main.async {
                        syncMessage = "⚠️ Upload failed: \(error ?? "Unknown error")\n\nPlease check your internet connection and try again."
                        showSyncAlert = true
                    }
                    return
                }
                
                // Download any new data from Drive
                storageService.syncFromGoogleDrive(accessToken: token) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            // IMPORTANT: Small delay to ensure file system has written the files
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                // Save current plan first
                                store.savePlan()
                                
                                // Reload the current plan after successful sync
                                store.loadPlan(for: store.selectedDate)
                                
                                // Trigger UI update
                                store.objectWillChange.send()
                                
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateStyle = .short
                                dateFormatter.timeStyle = .short
                                let timeString = dateFormatter.string(from: Date())
                                
                                syncMessage = "✓ Sync Completed!\n\n• Uploaded your local plans\n• Downloaded latest plans from other devices\n• Reloaded current view with latest data\n• Last synced: \(timeString)\n\nAll your devices now have the same data."
                                showSyncAlert = true
                            }
                        } else {
                            syncMessage = "⚠️ Download failed: \(error ?? "Unknown error")\n\nYour local data was uploaded, but couldn't download changes from other devices."
                            showSyncAlert = true
                        }
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Share Sheet

