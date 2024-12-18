//
//  FindingMatchView.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import SwiftUI

struct FindingMatchView: View {
    @ObservedObject var wsManager = WebSocketManager.shared
    @State private var navigateToGame = false // State to trigger navigation
    @Binding var isFindingMatch: Bool

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Finding Match...")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                    .padding()
                Spacer()
                
                Button("Cancel") {
                    wsManager.disconnectWebSocket()
                    isFindingMatch = false
                }
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .frame(width: 200)
                .background(Color.red)
                .cornerRadius(10)
                
                Spacer()
            }
            .onAppear {
                wsManager.connectWebSocket() // Connect when FindingMatchView appears
                wsManager.sendFindMatch()    // Send the find-match request
                observeMatchFound()
            }
            .navigationDestination(isPresented: $navigateToGame) {
                MultiplayerSpinnerGameView(isFindingMatch: $isFindingMatch)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }

    // MARK: - Observe Match Found
    func observeMatchFound() {
        NotificationCenter.default.addObserver(forName: .matchFound, object: nil, queue: .main) { _ in
            DispatchQueue.main.async {
                self.navigateToGame = true
            }
        }
    }
}
