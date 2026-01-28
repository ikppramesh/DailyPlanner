import Foundation

class DataStorageService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        // Use shared app group container for data sync across devices
        // Falls back to local documents directory
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DailyPlanner", isDirectory: true)
    }

    init() {
        // Create directory if needed
        try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        // Restore last sync date
        lastSyncDate = UserDefaults.standard.object(forKey: "last_sync_date") as? Date
    }

    private func fileURL(for date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = formatter.string(from: date)
        return documentsDirectory.appendingPathComponent("\(filename).json")
    }

    func save(plan: DayPlan, for date: Date) {
        let url = fileURL(for: date)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(plan)
            // Use atomicWrite to prevent data corruption
            try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Failed to save plan for \(date): \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }

    func load(for date: Date) -> DayPlan? {
        let url = fileURL(for: date)
        guard fileManager.fileExists(atPath: url.path) else { 
            print("No plan file exists for date: \(date)")
            return nil 
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try Data(contentsOf: url)
            let plan = try decoder.decode(DayPlan.self, from: data)
            print("Successfully loaded plan for \(date) with \(plan.tasks.count) tasks")
            return plan
        } catch {
            print("Failed to load plan for \(date): \(error)")
            print("Error details: \(error.localizedDescription)")
            return nil
        }
    }

    func deletePlan(for date: Date) {
        let url = fileURL(for: date)
        try? fileManager.removeItem(at: url)
    }

    /// Returns all dates that have saved plans
    func savedDates() -> [Date] {
        guard let files = try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return files.compactMap { url -> Date? in
            let name = url.deletingPathExtension().lastPathComponent
            return formatter.date(from: name)
        }.sorted()
    }
    
    // MARK: - Google Drive Sync
    
    private let driveAPIBase = "https://www.googleapis.com/drive/v3"
    private let uploadAPIBase = "https://www.googleapis.com/upload/drive/v3"
    private var driveFolderID: String? {
        get { UserDefaults.standard.string(forKey: "drive_folder_id") }
        set { UserDefaults.standard.set(newValue, forKey: "drive_folder_id") }
    }
    
    /// Sync all local plans to Google Drive
    func syncToGoogleDrive(accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async {
            self.isSyncing = true
            self.syncError = nil
        }
        
        // First, ensure the DailyPlannerSync folder exists
        ensureDriveFolder(accessToken: accessToken) { [weak self] success, folderID in
            guard let self = self, success, let folderID = folderID else {
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    self?.syncError = "Failed to access Drive folder"
                }
                completion(false, "Failed to access Drive folder")
                return
            }
            
            self.driveFolderID = folderID
            
            // Get all local files
            let dates = self.savedDates()
            let group = DispatchGroup()
            var hasError = false
            var errorMsg: String?
            
            for date in dates {
                group.enter()
                self.uploadPlanToDrive(date: date, folderID: folderID, accessToken: accessToken) { success, error in
                    if !success {
                        hasError = true
                        errorMsg = error
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.isSyncing = false
                if hasError {
                    self.syncError = errorMsg
                    completion(false, errorMsg)
                } else {
                    self.lastSyncDate = Date()
                    UserDefaults.standard.set(Date(), forKey: "last_sync_date")
                    completion(true, nil)
                }
            }
        }
    }
    
    /// Download all plans from Google Drive
    func syncFromGoogleDrive(accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async {
            self.isSyncing = true
            self.syncError = nil
        }
        
        guard let folderID = driveFolderID else {
            // Need to find or create folder first
            ensureDriveFolder(accessToken: accessToken) { [weak self] success, folderID in
                guard let self = self, success, let folderID = folderID else {
                    DispatchQueue.main.async {
                        self?.isSyncing = false
                        self?.syncError = "Failed to access Drive folder"
                    }
                    completion(false, "Failed to access Drive folder")
                    return
                }
                self.driveFolderID = folderID
                self.downloadAllPlans(folderID: folderID, accessToken: accessToken, completion: completion)
            }
            return
        }
        
        downloadAllPlans(folderID: folderID, accessToken: accessToken, completion: completion)
    }
    
    private func ensureDriveFolder(accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        // First check if folder already exists
        let query = "name='DailyPlannerSync' and mimeType='application/vnd.google-apps.folder' and trashed=false"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = URL(string: "\(driveAPIBase)/files?q=\(encodedQuery)&fields=files(id,name)")!
        
        var request = URLRequest(url: searchURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let files = json["files"] as? [[String: Any]],
               let firstFile = files.first,
               let folderID = firstFile["id"] as? String {
                // Folder exists
                completion(true, folderID)
                return
            }
            
            // Create folder
            self.createDriveFolder(accessToken: accessToken, completion: completion)
        }.resume()
    }
    
    private func createDriveFolder(accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        let createURL = URL(string: "\(driveAPIBase)/files")!
        var request = URLRequest(url: createURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": "DailyPlannerSync",
            "mimeType": "application/vnd.google-apps.folder"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let folderID = json["id"] as? String {
                completion(true, folderID)
            } else {
                completion(false, nil)
            }
        }.resume()
    }
    
    private func uploadPlanToDrive(date: Date, folderID: String, accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "\(formatter.string(from: date)).json"
        
        guard let plan = load(for: date) else {
            completion(false, "Failed to load local plan")
            return
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let jsonData = try? encoder.encode(plan) else {
            completion(false, "Failed to encode plan")
            return
        }
        
        // Check if file already exists
        checkFileExists(filename: filename, folderID: folderID, accessToken: accessToken) { existingFileID in
            if let fileID = existingFileID {
                // Update existing file
                self.updateDriveFile(fileID: fileID, jsonData: jsonData, accessToken: accessToken, completion: completion)
            } else {
                // Create new file
                self.createDriveFile(filename: filename, folderID: folderID, jsonData: jsonData, accessToken: accessToken, completion: completion)
            }
        }
    }
    
    private func checkFileExists(filename: String, folderID: String, accessToken: String, completion: @escaping (String?) -> Void) {
        let query = "name='\(filename)' and '\(folderID)' in parents and trashed=false"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = URL(string: "\(driveAPIBase)/files?q=\(encodedQuery)&fields=files(id)")!
        
        var request = URLRequest(url: searchURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let files = json["files"] as? [[String: Any]],
               let firstFile = files.first,
               let fileID = firstFile["id"] as? String {
                completion(fileID)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    private func createDriveFile(filename: String, folderID: String, jsonData: Data, accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        let uploadURL = URL(string: "\(uploadAPIBase)/files?uploadType=multipart")!
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let metadata: [String: Any] = [
            "name": filename,
            "parents": [folderID]
        ]
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(try! JSONSerialization.data(withJSONObject: metadata))
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(jsonData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                completion(true, nil)
            } else {
                completion(false, "Upload failed")
            }
        }.resume()
    }
    
    private func updateDriveFile(fileID: String, jsonData: Data, accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        let uploadURL = URL(string: "\(uploadAPIBase)/files/\(fileID)?uploadType=media")!
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                completion(true, nil)
            } else {
                completion(false, "Update failed")
            }
        }.resume()
    }
    
    private func downloadAllPlans(folderID: String, accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        // List all files in folder
        let listURL = URL(string: "\(driveAPIBase)/files?q='\(folderID)'+in+parents+and+trashed=false&fields=files(id,name)")!
        var request = URLRequest(url: listURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let files = json["files"] as? [[String: Any]] else {
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    self?.syncError = "Failed to list Drive files"
                }
                completion(false, "Failed to list Drive files")
                return
            }
            
            let group = DispatchGroup()
            var hasError = false
            var errorMsg: String?
            
            for file in files {
                guard let fileID = file["id"] as? String,
                      let filename = file["name"] as? String else { continue }
                
                group.enter()
                self.downloadDriveFile(fileID: fileID, filename: filename, accessToken: accessToken) { success, error in
                    if !success {
                        hasError = true
                        errorMsg = error
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.isSyncing = false
                if hasError {
                    self.syncError = errorMsg
                    completion(false, errorMsg)
                } else {
                    self.lastSyncDate = Date()
                    UserDefaults.standard.set(Date(), forKey: "last_sync_date")
                    completion(true, nil)
                }
            }
        }.resume()
    }
    
    private func downloadDriveFile(fileID: String, filename: String, accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        let downloadURL = URL(string: "\(driveAPIBase)/files/\(fileID)?alt=media")!
        var request = URLRequest(url: downloadURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data else {
                completion(false, "Download failed")
                return
            }
            
            // Parse filename to get date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = filename.replacingOccurrences(of: ".json", with: "")
            
            guard let date = formatter.date(from: dateString) else {
                completion(false, "Invalid filename format")
                return
            }
            
            // Decode and save
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let plan = try decoder.decode(DayPlan.self, from: data)
                // Save to local storage
                self.save(plan: plan, for: date)
                // Verify the save was successful by reading it back
                if let _ = self.load(for: date) {
                    completion(true, nil)
                } else {
                    completion(false, "Failed to verify saved plan")
                }
            } catch {
                completion(false, "Failed to decode plan: \(error.localizedDescription)")
            }
        }.resume()
    }
}
