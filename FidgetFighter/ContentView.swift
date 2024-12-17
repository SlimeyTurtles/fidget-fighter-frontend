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
    @State private var rpm: Double = 0                       // My current RPM
    @State private var opponentRPM: Double = 0               // Opponent's RPM
    
    @State private var timer: Timer? = nil                   // Timer for momentum simulation
    @State private var opponentTimer: Timer? = nil           // Timer for opponent's spinner
    
    @State private var lastDragTime: Date? = nil             // For calculating drag velocity
    @State private var lastDragValue: CGFloat = 0            // Last drag position
    
    let friction: Double = 0.98                              // Friction factor
    
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
                connectWebSocket() // Connect manually
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
                            handleDrag(value: value)
                        }
                        .onEnded { _ in
                            calculateRPMAndSend()
                        }
                )
                .padding()
            
            Text("Your RPM: \(Int(rpm))")
                .font(.title2)
                .padding()
            
            Spacer()
        }
        .onDisappear {
            socketTask?.cancel()
            timer?.invalidate()
            opponentTimer?.invalidate()
        }
    }
    
    // MARK: - WebSocket Connection
    func connectWebSocket() {
        guard let url = URL(string: "ws://192.168.1.45:3000") else { return }
        socketTask = URLSession.shared.webSocketTask(with: url)
        socketTask?.resume()
        
        statusMessage = "Connecting..."
        listenForMessages()
        sendFindMatch()
    }
    
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
    
    // MARK: - Handle Drag and Send RPM
    func handleDrag(value: DragGesture.Value) {
        let currentTime = Date()
        let deltaTime = currentTime.timeIntervalSince(lastDragTime ?? currentTime)
        
        if deltaTime > 0 {
            let dragDistance = value.translation.width - lastDragValue
            let velocity = Double(dragDistance) / deltaTime
            rpm = velocity / 6.0 // Convert velocity to RPM
        }
        
        lastDragTime = currentTime
        lastDragValue = value.translation.width
    }
    
    func calculateRPMAndSend() {
        lastDragTime = nil
        lastDragValue = 0
        
        sendRPMUpdate()
        startMomentumTimer()
    }
    
    func startMomentumTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            if abs(rpm) > 0.1 {
                myAngle += rpm * 0.016 * 6.0
                rpm *= friction
            } else {
                rpm = 0
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Send RPM Update to Server
    func sendRPMUpdate() {
        let spinData: [String: Any] = ["event": "spin-update", "rpm": rpm]
        if let jsonData = try? JSONSerialization.data(withJSONObject: spinData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            socketTask?.send(message) { error in
                if let error = error {
                    print("Error sending spin update: \(error.localizedDescription)")
                } else {
                    print("Sent RPM update: \(jsonString)")
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
                    print("Received string message: (text)")
                    handleServerMessage(text)
                case .data(let data):
                    // Convert binary data to a string
                    if let text = String(data: data, encoding: .utf8) {
                        print("Received binary message as string: (text)")
                        handleServerMessage(text)
                    } else {
                        print("Failed to decode binary message")
                    }
                @unknown default:
                    print("Unknown WebSocket message type")
                }
                // Keep listening for more messages
                listenForMessages()
            case .failure(let error):
                print("WebSocket error: (error.localizedDescription)")
                statusMessage = "Disconnected: (error.localizedDescription)"
            }
        }
    }
    // MARK: - Handle Server Messages
    func handleServerMessage(_ message: String) {
        if let data = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let event = json["event"] as? String {
            if event == "spin-update", let receivedRPM = json["rpm"] as? Double {
                DispatchQueue.main.async {
                    print("Received RPM: \(receivedRPM)") // Log received RPM
                    opponentRPM = receivedRPM
                    startOpponentMomentum()
                }
            } else if event == "start-game", let matchMessage = json["message"] as? String {
                DispatchQueue.main.async {
                    statusMessage = matchMessage
                }
            }
        }
    }
    
    // MARK: - Opponent Momentum
    func startOpponentMomentum() {
        opponentTimer?.invalidate()
        opponentTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            if abs(opponentRPM) > 0.1 {
                opponentAngle += opponentRPM * 0.016 * 6.0
                opponentRPM *= friction
            } else {
                opponentRPM = 0
                opponentTimer?.invalidate()
            }
        }
    }
}
