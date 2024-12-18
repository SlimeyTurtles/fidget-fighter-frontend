//
//  ContentView.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/16/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isFindingMatch = false

    var body: some View {
        if isFindingMatch {
            FindingMatchView(isFindingMatch: $isFindingMatch)
        } else {
            HomeView(isFindingMatch: $isFindingMatch)
        }
    }
}
