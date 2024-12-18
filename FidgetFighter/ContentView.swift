//
//  ContentView.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/16/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isFindingMatch = false
    @StateObject private var userData = UserData()

    var body: some View {
        if isFindingMatch {
            FindingMatchView(isFindingMatch: $isFindingMatch)
                .environmentObject(userData)
        } else {
            HomeView(isFindingMatch: $isFindingMatch)
                .environmentObject(userData)
                .background(Color(red: 1.0, green: 0.85, blue: 0.65).edgesIgnoringSafeArea(.all))
        }
    }
}
