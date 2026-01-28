import Foundation
import AuthenticationServices
import SwiftUI

/// Google Calendar integration using OAuth2 and REST API.
///
/// Ensure the Google Calendar API is enabled in your Google Cloud Console
/// and the OAuth consent screen is configured for your project.
class GoogleCalendarService: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?

    private let clientID = "800047604147-d9tlkf24hg40t8omphqpi1mpmufbl7tv.apps.googleusercontent.com"
    private let redirectURI = "com.googleusercontent.apps.800047604147-d9tlkf24hg40t8omphqpi1mpmufbl7tv:/oauth2redirect"
    private let scope = "https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/drive.file"
    private let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenURL = "https://oauth2.googleapis.com/token"
    private let calendarAPIBase = "https://www.googleapis.com/calendar/v3"

    private var accessToken: String? {
        didSet {
            isAuthenticated = accessToken != nil
            if let token = accessToken {
                UserDefaults.standard.set(token, forKey: "google_access_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "google_access_token")
            }
        }
    }

    private var refreshToken: String? {
        didSet {
            if let token = refreshToken {
                UserDefaults.standard.set(token, forKey: "google_refresh_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "google_refresh_token")
            }
        }
    }
    
    private var tokenExpiryDate: Date? {
        get { UserDefaults.standard.object(forKey: "google_token_expiry") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "google_token_expiry") }
    }

    override init() {
        super.init()
        // Restore tokens
        accessToken = UserDefaults.standard.string(forKey: "google_access_token")
        refreshToken = UserDefaults.standard.string(forKey: "google_refresh_token")
        
        // Check if token is expired and refresh if needed
        if let expiry = tokenExpiryDate, expiry < Date(), refreshToken != nil {
            refreshAccessToken { _ in }
        }
    }

    // MARK: - Authentication

    func signIn() {
        var components = URLComponents(string: authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let url = components.url else { return }

        // Use ASWebAuthenticationSession for OAuth
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "com.googleusercontent.apps.800047604147-d9tlkf24hg40t8omphqpi1mpmufbl7tv"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let callbackURL = callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                return
            }

            self.exchangeCodeForToken(code: code)
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }

    func signOut() {
        accessToken = nil
        refreshToken = nil
    }

    private func exchangeCodeForToken(code: String) {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "code": code,
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]

        request.httpBody = body.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    self?.accessToken = json["access_token"] as? String
                    if let refreshToken = json["refresh_token"] as? String {
                        self?.refreshToken = refreshToken
                    }
                    // Set token expiry (default 3600 seconds = 1 hour)
                    if let expiresIn = json["expires_in"] as? Int {
                        self?.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn - 300)) // Refresh 5 min early
                    }
                }
            }
        }.resume()
    }

    private func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = refreshToken else {
            completion(false)
            return
        }

        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "refresh_token": refreshToken,
            "client_id": clientID,
            "grant_type": "refresh_token"
        ]

        request.httpBody = body.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access_token"] as? String {
                DispatchQueue.main.async {
                    self?.accessToken = token
                    // Update expiry time
                    if let expiresIn = json["expires_in"] as? Int {
                        self?.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn - 300))
                    }
                    completion(true)
                }
            } else {
                completion(false)
            }
        }.resume()
    }
    
    // MARK: - Access Token for Drive Sync
    
    /// Get current access token, refreshing if needed
    func getAccessToken(completion: @escaping (String?) -> Void) {
        // Check if token exists and is not expired
        if let token = accessToken,
           let expiry = tokenExpiryDate,
           expiry > Date() {
            completion(token)
            return
        }
        
        // Token expired or missing, try to refresh
        if refreshToken != nil {
            refreshAccessToken { [weak self] success in
                if success {
                    completion(self?.accessToken)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }

    // MARK: - Calendar API

    func fetchEvents(for date: Date, completion: @escaping ([CalendarEvent]) -> Void) {
        guard let accessToken = accessToken else {
            completion([])
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let formatter = ISO8601DateFormatter()
        let timeMin = formatter.string(from: startOfDay)
        let timeMax = formatter.string(from: endOfDay)

        var components = URLComponents(string: "\(calendarAPIBase)/calendars/primary/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeMax", value: timeMax),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                // Token expired, refresh
                self?.refreshAccessToken { success in
                    if success {
                        self?.fetchEvents(for: date, completion: completion)
                    } else {
                        DispatchQueue.main.async { completion([]) }
                    }
                }
                return
            }

            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    let events: [CalendarEvent] = items.compactMap { item in
                        guard let id = item["id"] as? String,
                              let summary = item["summary"] as? String,
                              let start = item["start"] as? [String: Any],
                              let end = item["end"] as? [String: Any] else { return nil }

                        let startDate: Date
                        let endDate: Date
                        let isoFormatter = ISO8601DateFormatter()
                        isoFormatter.formatOptions = [.withInternetDateTime]

                        if let dateTimeStr = start["dateTime"] as? String {
                            startDate = isoFormatter.date(from: dateTimeStr) ?? date
                        } else if let dateStr = start["date"] as? String {
                            let df = DateFormatter()
                            df.dateFormat = "yyyy-MM-dd"
                            startDate = df.date(from: dateStr) ?? date
                        } else {
                            return nil
                        }

                        if let dateTimeStr = end["dateTime"] as? String {
                            endDate = isoFormatter.date(from: dateTimeStr) ?? date
                        } else if let dateStr = end["date"] as? String {
                            let df = DateFormatter()
                            df.dateFormat = "yyyy-MM-dd"
                            endDate = df.date(from: dateStr) ?? date
                        } else {
                            return nil
                        }

                        return CalendarEvent(
                            id: id,
                            title: summary,
                            startTime: startDate,
                            endTime: endDate,
                            colorHex: nil
                        )
                    }

                    DispatchQueue.main.async {
                        completion(events)
                    }
                }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension GoogleCalendarService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
