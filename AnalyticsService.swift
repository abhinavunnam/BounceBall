//
//  AnalyticsService.swift
//  BounceBall
//
//  Session and event tracking service using Supabase
//

import Foundation
import UIKit

class AnalyticsService {
    static let shared = AnalyticsService()
    
    // Current session info
    private var currentSessionId: String?
    private var sessionStartTime: Date?
    
    private init() {}
    
    // MARK: - Session Management
    
    /// Start a new session when app launches
    func startSession() {
        sessionStartTime = Date()
        
        let playerId = GameCenterHelper.shared.getCurrentPlayerId()
        let deviceModel = getDeviceModel()
        let osVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        let sessionData: [String: Any] = [
            "player_id": playerId,
            "device_model": deviceModel,
            "os_version": osVersion,
            "app_version": appVersion
        ]
        
        postToSupabase(
            endpoint: SupabaseConfig.sessionsEndpoint,
            data: sessionData
        ) { [weak self] result in
            switch result {
            case .success(let response):
                // Extract session ID from response
                if let sessions = response as? [[String: Any]],
                   let firstSession = sessions.first,
                   let sessionId = firstSession["id"] as? String {
                    self?.currentSessionId = sessionId
                    print("AnalyticsService: Session started with ID: \(sessionId)")
                }
            case .failure(let error):
                print("AnalyticsService: Failed to start session - \(error.localizedDescription)")
            }
        }
    }
    
    /// End the current session when app goes to background
    func endSession() {
        guard let sessionId = currentSessionId,
              let startTime = sessionStartTime else {
            print("AnalyticsService: No active session to end")
            return
        }
        
        let duration = Int(Date().timeIntervalSince(startTime))
        
        let updateData: [String: Any] = [
            "ended_at": ISO8601DateFormatter().string(from: Date()),
            "duration_seconds": duration
        ]
        
        patchToSupabase(
            endpoint: "\(SupabaseConfig.sessionsEndpoint)?id=eq.\(sessionId)",
            data: updateData
        ) { result in
            switch result {
            case .success:
                print("AnalyticsService: Session ended (duration: \(duration)s)")
            case .failure(let error):
                print("AnalyticsService: Failed to end session - \(error.localizedDescription)")
            }
        }
        
        // Reset session state
        currentSessionId = nil
        sessionStartTime = nil
    }
    
    // MARK: - Level Event Tracking
    
    /// Track when a level is started
    func trackLevelStarted(levelIndex: Int) {
        trackLevelEvent(levelIndex: levelIndex, eventType: "started", attempts: 1)
    }
    
    /// Track when a level is completed
    func trackLevelCompleted(levelIndex: Int, attempts: Int) {
        trackLevelEvent(levelIndex: levelIndex, eventType: "completed", attempts: attempts)
    }
    
    /// Track when a level attempt fails (ball out of bounds)
    func trackLevelFailed(levelIndex: Int, attempts: Int) {
        trackLevelEvent(levelIndex: levelIndex, eventType: "failed", attempts: attempts)
    }
    
    private func trackLevelEvent(levelIndex: Int, eventType: String, attempts: Int) {
        let playerId = GameCenterHelper.shared.getCurrentPlayerId()
        
        var eventData: [String: Any] = [
            "player_id": playerId,
            "level_index": levelIndex,
            "event_type": eventType,
            "attempts": attempts
        ]
        
        // Include session ID if available
        if let sessionId = currentSessionId {
            eventData["session_id"] = sessionId
        }
        
        postToSupabase(
            endpoint: SupabaseConfig.levelEventsEndpoint,
            data: eventData
        ) { result in
            switch result {
            case .success:
                print("AnalyticsService: Tracked \(eventType) for level \(levelIndex)")
            case .failure(let error):
                print("AnalyticsService: Failed to track event - \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Network Helpers
    
    private func postToSupabase(endpoint: String, data: [String: Any], completion: @escaping (Result<Any, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "AnalyticsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        for (key, value) in SupabaseConfig.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AnalyticsService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data)
                print("AnalyticsService Response: \(json)")
                completion(.success(json))
            } catch {
                // Try to print raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("AnalyticsService Raw Response: \(responseString)")
                }
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func patchToSupabase(endpoint: String, data: [String: Any], completion: @escaping (Result<Any, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "AnalyticsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        
        for (key, value) in SupabaseConfig.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success([:]))
        }.resume()
    }
    
    // MARK: - Device Info
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
