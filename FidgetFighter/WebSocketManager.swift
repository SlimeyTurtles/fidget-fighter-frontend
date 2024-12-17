//
//  WebSocketManager.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//


import Foundation

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    @Published var socketTask: URLSessionWebSocketTask?
    private let url = URL(string: AppConstants.webSocketURL)!
    
    @Published var matchFound = false
    @Published var opponentRPM: Double = 0.0
    @Published var serverMessage: String = ""
    
    private init() {
        connectWebSocket()
    }
    
    func connectWebSocket() {
        socketTask = URLSession.shared.webSocketTask(with: url)
        socketTask?.resume()
        print("WebSocket connected")
        
        listenForMessages()
    }
    
    func sendFindMatch() {
        let message = URLSessionWebSocketTask.Message.string("{\"event\": \"find-match\"}")
        socketTask?.send(message) { error in
            if let error = error {
                print("Error sending find-match: \(error.localizedDescription)")
            } else {
                print("Sent find-match request")
            }
        }
    }
    
    func sendRPMUpdate(rpm: Double) {
        let message = "{\"event\": \"spin-update\", \"rpm\": \(rpm)}"
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        socketTask?.send(wsMessage) { error in
            if let _ = error {
                print("Error sending RPM update: (error.localizedDescription)")
            } else {
                print("Successfully sent RPM update: (message)")
            }
        }
    }
    
    private func listenForMessages() {
        socketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received: \(text)")
                    self.handleServerMessage(text)
                case .data:
                    print("Unsupported binary message received")
                @unknown default:
                    print("Unknown message type received")
                }
            case .failure(let error):
                print("WebSocket error: \(error.localizedDescription)")
            }
            
            // Always keep listening for new messages
            self.listenForMessages()
        }
    }
    
    private func handleServerMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String else { return }
        
        switch event {
        case "start-game":
            print("Match found! Starting the game...")
            DispatchQueue.main.async {
                self.matchFound = true
            }
        case "spin-update":
            if let receivedRPM = json["rpm"] as? Double {
                print("Received opponent RPM: (receivedRPM)")
                DispatchQueue.main.async {
                    self.opponentRPM = receivedRPM
                    NotificationCenter.default.post(name: .opponentRPMUpdated, object: nil, userInfo: ["rpm": receivedRPM])
                }
            }
        default:
            print("Unrecognized event: \(event)")
        }
    }
}
