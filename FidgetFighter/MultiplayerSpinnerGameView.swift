//
//  MultiplayerSpinnerGameView.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import SwiftUI

struct MultiplayerSpinnerGameView: View {
    @ObservedObject var wsManager = WebSocketManager.shared
    
    @State private var myAngle: Double = 0                  // My spinner angle
    @State private var opponentAngle: Double = 0            // Opponent spinner angle
    @State private var rpm: Double = 0                      // My RPM
    @State private var opponentRPM: Double = 0              // Opponent RPM
    
    @State private var dragStartTime: Date? = nil           // Start time of drag
    @State private var lastDragValue: CGFloat = 0           // Last drag position
    
    @State private var timer: Timer? = nil                  // Timer for my spinner momentum
    @State private var opponentTimer: Timer? = nil          // Timer for opponent spinner momentum
    
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
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(myAngle))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleDrag(value: value)
                            }
                            .onEnded { value in
                                calculateRPMAndSend(velocity: value.velocity)
                            }
                    )
                Text("RPM: \(Int(rpm))")
                    .font(.title3)
                    .padding()
            }
            Spacer()
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: .opponentRPMUpdated, object: nil, queue: .main) { notification in
                if let userInfo = notification.userInfo,
                   let newRPM = userInfo["rpm"] as? Double {
                    print("API message received: Opponent RPM = \(newRPM)")
                    startOpponentMomentumTimer(rpm: newRPM)
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .opponentRPMUpdated, object: nil)
        }
    }
    
    // MARK: - Handle Drag Gesture
    func handleDrag(value: DragGesture.Value) {
        let currentTime = Date()
        let deltaTime = currentTime.timeIntervalSince(dragStartTime ?? currentTime)
        
        if deltaTime > 0 { // Avoid division by zero
            let dragDistance = value.translation.width - lastDragValue
            let velocity = Double(dragDistance) / deltaTime // Distance over time
            rpm = velocity / 6.0 // Scale velocity to RPM
        }
        
        dragStartTime = currentTime
        lastDragValue = value.translation.width
    }
    
    // MARK: - Calculate RPM and Send to Server
    func calculateRPMAndSend(velocity: CGSize) {
        dragStartTime = nil
        lastDragValue = 0
        
        print("Sending RPM: \(Int(rpm))")
        wsManager.sendRPMUpdate(rpm: rpm)
        startMomentumTimer()
    }
    
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
}
