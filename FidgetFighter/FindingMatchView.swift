//
//  FindingMatchView.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import SwiftUI

struct FindingMatchView: View {
    @ObservedObject var wsManager = WebSocketManager.shared

    var body: some View {
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
        }
        .onAppear {
            wsManager.sendFindMatch()
        }
        .navigationDestination(isPresented: $wsManager.matchFound) {
            MultiplayerSpinnerGameView()
        }
    }
}
