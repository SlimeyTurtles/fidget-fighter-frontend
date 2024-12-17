//
//  HomeView.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import SwiftUI

struct HomeView: View {
    @State private var isFindingMatch = false

    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to Spinner Game")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Button(action: {
                isFindingMatch = true // Go to Finding Match View
            }) {
                Text("Find Match")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            Spacer()
        }
        .navigationDestination(isPresented: $isFindingMatch) {
            FindingMatchView()
        }
    }
}
