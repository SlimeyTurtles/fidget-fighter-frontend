//
//  WebSocketManager.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import Foundation

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()

    private var socketTask: URLSessionWebSocketTask?
    private let url: URL = URL(string: AppConstants.webSocketURL)!
    
    @Published var opponentRPM: Double = 0.0 // Latest RPM from the opponent
    @Published var gameResult: (winner: String, player1RPM: Double, player2RPM: Double)? = nil

    private init() {}

    // MARK: - Connect to WebSocket
    func connectWebSocket() {
        guard socketTask == nil else { return }
        socketTask = URLSession.shared.webSocketTask(with: url)
        socketTask?.resume()
        print("WebSocket connected")
        listenForMessages()
    }

    // MARK: - Disconnect WebSocket
    func disconnectWebSocket() {
        print("Disconnecting WebSocket...")
        socketTask?.cancel(with: .goingAway, reason: "User navigated away".data(using: .utf8))
        socketTask = nil
        reset()
    }

    // MARK: - Send Find Match Request
    func sendFindMatch() {
        let message = "{\"event\": \"find-match\"}"
        sendMessage(message)
    }

    // MARK: - Send RPM Update
    func sendRPMUpdate(rpm: Double) {
        let message = "{\"event\": \"spin-update\", \"rpm\": \(rpm)}"
        sendMessage(message)
    }

    private func sendMessage(_ message: String) {
        guard let task = socketTask else { return }
        task.send(.string(message)) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Listen for Messages
    private func listenForMessages() {
        socketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleServerMessage(text)
                default:
                    print("Unsupported message type")
                }
            case .failure(let error):
                print("WebSocket error: \(error.localizedDescription)")
            }
            self.listenForMessages() // Continue listening
        }
    }

    private func handleServerMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String else { return }

        switch event {
        case "start-game":
            NotificationCenter.default.post(name: .matchFound, object: nil)
        case "spin-update":
            if let receivedRPM = json["rpm"] as? Double {
                NotificationCenter.default.post(name: .opponentRPMUpdated, object: nil, userInfo: ["rpm": receivedRPM])
            }
        case "game-over":
                if let result = json["result"] as? String,
                   let player1RPMString = json["player1RPM"] as? String,
                   let player2RPMString = json["player2RPM"] as? String,
                   let player1RPM = Double(player1RPMString),
                   let player2RPM = Double(player2RPMString) {

                    print("Game Over Event Received: \(result), Player 1 RPM: \(player1RPM), Player 2 RPM: \(player2RPM)")

                    DispatchQueue.main.async {
                        self.gameResult = (result, player1RPM, player2RPM)
                        NotificationCenter.default.post(name: .gameOver, object: nil)
                    }
                } else {
                    print("Failed to parse game-over JSON fields.")
                }
        default:
            print("Unrecognized event: \(event)")
        }
    }

    func reset() {
        opponentRPM = 0.0
        gameResult = nil
    }
}
