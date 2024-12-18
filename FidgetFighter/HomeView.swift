//
//  HomeView.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import SwiftUI

struct HomeView: View {
    @Binding var isFindingMatch: Bool
    @EnvironmentObject var userData: UserData
    @State private var showPopup = false
    
    @State private var angle: Double = 0 // Current angle of the spinning object
    @State private var rpm: Double = 0   // Spinning speed
    @State private var dragStartTime: Date? = nil
    @State private var lastDragValue: CGFloat = 0
    @State private var timer: Timer? = nil
    
    let friction: Double = 0.98
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Wins: \(userData.wins)")
                Spacer()
                Text("Losses: \(userData.losses)")
                Spacer()
            }
            .foregroundColor(.black)
            Spacer()
            Image(systemName: userData.spinningItem.isEmpty ? "gear" : userData.spinningItem)
                .resizable()
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(angle))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDrag(value: value)
                        }
                        .onEnded { _ in
                            calculateRPMAndStartMomentum()
                        }
                )
                .foregroundColor(.blue)
                .padding()
            Text("RPM: \(Int(rpm))")
                .foregroundColor(.black)
            Spacer()
            
            Button("Find Match") {
                isFindingMatch = true
            }
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .frame(width: 200)
            .background(Color.orange)
            .cornerRadius(10)
            
            Button("Choose Spinning Item") {
                showPopup = true
            }
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .frame(width: 200)
            .background(Color.orange)
            .cornerRadius(10)
            .sheet(isPresented: $showPopup) {
                SpinningItemPicker()
            }
            Spacer()
        }
    }
    
    // MARK: - Handle Drag Gesture
    func handleDrag(value: DragGesture.Value) {
        if dragStartTime == nil {
            dragStartTime = Date() // Initialize drag start time
            lastDragValue = value.translation.width
        }

        let dragDistance = value.translation.width - lastDragValue
        let currentTime = Date()
        let deltaTime = currentTime.timeIntervalSince(dragStartTime ?? currentTime)

        if deltaTime > 0 { // Avoid division by zero
            let velocity = Double(dragDistance) / deltaTime
            rpm = abs(velocity / 6.0) // Scale velocity to RPM
        }

        lastDragValue = value.translation.width
        dragStartTime = currentTime
    }

    // MARK: - Calculate RPM and Start Momentum
    func calculateRPMAndStartMomentum() {
        dragStartTime = nil
        lastDragValue = 0

        timer?.invalidate() // Stop previous momentum timer

        // Start a new momentum timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            if abs(rpm) > 0.1 { // Apply friction until RPM stops
                angle += rpm * 0.016 * 6.0
                rpm *= friction
            } else {
                rpm = 0
                timer?.invalidate()
            }
        }
    }
}
