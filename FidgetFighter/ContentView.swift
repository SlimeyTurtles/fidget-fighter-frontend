//
//  ContentView.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/16/24.
//

import SwiftUI

struct MultiplayerSpinnerGameView: View {
    @State private var socketTask: URLSessionWebSocketTask?   // WebSocket task
    @State private var statusMessage = "Disconnected"        // Status message
    @State private var myAngle: Double = 0                   // My spinner angle
    @State private var opponentAngle: Double = 0             // Opponent spinner angle
    @State private var lastDragValue: CGFloat = 0            // Track drag for spinning
    
    var body: some View {
        VStack {
            // Opponent's Spinner
            Text("Opponent's Spinner")
                .font(.headline)
                .padding()
            Image(systemName: "gear")
                .resizable()
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(opponentAngle))
                .foregroundColor(.red)
                .padding()
            
            Spacer()
            
            // Status Message and Connect Button
            Text(statusMessage)
                .font(.title2)
                .padding()
            
            Button("Connect to Server") {
                connectWebSocket() // Call the WebSocket connection manually
            }
            .font(.title2)
            .padding()
            
            Spacer()
            
            // My Spinner with Drag Gesture
            Text("Your Spinner")
                .font(.headline)
                .padding()
            Image(systemName: "gear")
                .resizable()
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(myAngle))
                .foregroundColor(.blue)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            spinGear(dragValue: value.translation.width)
                        }
                        .onEnded { _ in
                            sendSpinUpdate() // Send angle update to the server
                        }
                )
                .padding()
            
            Spacer()
        }
        .onDisappear {
            socketTask?.cancel()
        }
    }
    
    // MARK: - WebSocket Connection
    func connectWebSocket() {
        guard let url = URL(string: "ws://192.168.1.45:3000") else { return }
        socketTask?.cancel() // Cancel any existing connection
        socketTask = URLSession.shared.webSocketTask(with: url)
        socketTask?.resume()
        
        statusMessage = "Connecting..."
        listenForMessages()
        
        sendFindMatch() // Send "find-match" event after connecting
    }
    
    // MARK: - Send "Find Match" Event
    func sendFindMatch() {
        let message = URLSessionWebSocketTask.Message.string("{\"event\": \"find-match\"}")
        socketTask?.send(message) { error in
            if let error = error {
                print("Error sending find-match: \(error.localizedDescription)")
                statusMessage = "Connection error: \(error.localizedDescription)"
            } else {
                statusMessage = "Finding a match..."
            }
        }
    }
    
    // MARK: - Spin Gear (Drag Logic)
    func spinGear(dragValue: CGFloat) {
        let rotationChange = (dragValue - lastDragValue) * 0.5 // Adjust sensitivity
        myAngle += Double(rotationChange)
        lastDragValue = dragValue
    }
    
    // MARK: - Send Spin Update
    func sendSpinUpdate() {
        lastDragValue = 0 // Reset drag tracking
        let spinData: [String: Any] = ["event": "spin-update", "angle": myAngle]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: spinData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            socketTask?.send(message) { error in
                if let error = error {
                    print("Error sending spin update: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Listen for Messages
    func listenForMessages() {
        socketTask?.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                    handleServerMessage(text)
                default:
                    break
                }
                listenForMessages() // Keep listening
            case .failure(let error):
                print("WebSocket error: \(error.localizedDescription)")
                statusMessage = "Disconnected: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Handle Messages from Server
    func handleServerMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String else { return }
        
        switch event {
        case "start-game":
            statusMessage = "Match found! Start spinning!"
        case "waiting":
            statusMessage = "Waiting for an opponent..."
        case "spin-update":
            if let angle = json["angle"] as? Double {
                opponentAngle = angle // Update opponent's spinner angle
            }
        default:
            print("Unhandled event: \(event)")
        }
    }
}
