//
//  MultiplayerSpinnerGameView.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import SwiftUI

struct MultiplayerSpinnerGameView: View {
    @ObservedObject var wsManager = WebSocketManager.shared
    @Binding var isFindingMatch: Bool
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userData: UserData
    
    @State private var myAngle: Double = 0                  // My spinner angle
    @State private var opponentAngle: Double = 0            // Opponent spinner angle
    @State private var rpm: Double = 0                      // My RPM
    @State private var opponentRPM: Double = 0              // Opponent RPM
    
    @State private var dragStartTime: Date? = nil           // Start time of drag
    @State private var lastDragValue: CGFloat = 0           // Last drag position
    
    @State private var timer: Timer? = nil                  // Timer for my spinner momentum
    @State private var opponentTimer: Timer? = nil          // Timer for opponent spinner momentum
    
    @State private var finalPlayerRPM: Double = 0       // Final player RPM after game ends
    @State private var finalOpponentRPM: Double = 0     // Final opponent RPM after game ends
    @State private var finalSpinDuration: Double = 3.0  // Duration for the final spin animation
    
    @State private var showOverlay = false
    @State private var resultMessage = ""
    @State private var disableDrag = false
    
    let friction: Double = 0.98                             // Friction factor

    var body: some View {
        VStack {
            // Opponent Spinner
            VStack {
                Text("Opponent RPM: \(Int(opponentRPM))")
                    .font(.title3)
                    .padding()
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(opponentAngle))
            }
            Spacer()
            
            // My Spinner
            VStack {
                Image(systemName: userData.spinningItem)
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(myAngle))
                    .gesture(
                        disableDrag ? nil : DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleDrag(value: value)
                            }
                            .onEnded { _ in
                                calculateRPMAndSend()
                            }
                    )
                Text("Your RPM: \(Int(rpm))")
                    .font(.title3)
                    .padding()
            }
            Spacer()
            
            // Game Over Overlay
            if showOverlay {
                Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                VStack {
                    Text(resultMessage)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                    Button("Back to Home") {
                        isFindingMatch = false
                        dismiss()
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    Button("Play Again") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            }
        }
        .onAppear {
            setupWebSocketObserver()
            observeGameOver()
        }
        .onDisappear {
            cleanupWebSocketObserver()
            wsManager.disconnectWebSocket()
            resetState()
        }
    }
    
    func resetState() {
        myAngle = 0
        opponentAngle = 0
        rpm = 0
        opponentRPM = 0
        disableDrag = false
        showOverlay = false
        
        timer?.invalidate()
        opponentTimer?.invalidate()
    }
    
    // MARK: - Handle Drag Gesture
    func handleDrag(value: DragGesture.Value) {
        let currentTime = Date()
        let deltaTime = currentTime.timeIntervalSince(dragStartTime ?? currentTime)
        
        if deltaTime > 0 { // Avoid division by zero
            let dragDistance = value.translation.width - lastDragValue
            let velocity = Double(dragDistance) / deltaTime // Distance over time
            rpm = abs(velocity / 6.0) // Scale velocity to RPM
            print(rpm)
        }
        
        dragStartTime = currentTime
        lastDragValue = value.translation.width
    }
    
    // MARK: - Calculate RPM and Send to Server
    func calculateRPMAndSend() {
        dragStartTime = nil
        lastDragValue = 0
        
        print("Sending RPM: \(Int(rpm))")
        wsManager.sendRPMUpdate(rpm: rpm)
        startMomentumTimer()
    }
    
    // MARK: - Start My Spinner Momentum
    func startMomentumTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            if abs(rpm) > 0.1 { // Apply friction until RPM stops
                myAngle += rpm * 0.016 * 6.0
                rpm *= friction
            } else {
                rpm = 0
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Start Opponent Spinner Momentum
    func startOpponentMomentumTimer(rpm: Double) {
        opponentTimer?.invalidate()
        opponentRPM = rpm
        
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

    // MARK: - WebSocket Observer
    func setupWebSocketObserver() {
        NotificationCenter.default.addObserver(forName: .opponentRPMUpdated, object: nil, queue: .main) { notification in
            if let userInfo = notification.userInfo,
               let newRPM = userInfo["rpm"] as? Double {
                print("API message received: Opponent RPM = \(newRPM)")
                startOpponentMomentumTimer(rpm: newRPM)
            }
        }
    }
    
    func cleanupWebSocketObserver() {
        NotificationCenter.default.removeObserver(self, name: .opponentRPMUpdated, object: nil)
    }
    
    // MARK: - Observe Game Over Event
    func observeGameOver() {
        NotificationCenter.default.addObserver(forName: .gameOver, object: nil, queue: .main) { _ in
            guard let result = wsManager.gameResult else { return }

            disableDrag = true // Prevent further user input

            print("Game Over - Final RPMs: Player = \(result.player1RPM), Opponent = \(result.player2RPM)")

            // Trigger final spin animations using the momentum timer
            rpm = result.player1RPM
            startMomentumTimer()

            opponentRPM = result.player2RPM
            startOpponentMomentumTimer(rpm: result.player2RPM)
            
            if (result.winner == "Player 1 Wins!") {
                userData.incrementWins()
            } else if (result.winner == "Player 2 Wins!") {
                userData.incrementLosses()
            }

            // Show the overlay after the final spin animation finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                resultMessage = result.winner
                showOverlay = true
            }
        }
    }
}
