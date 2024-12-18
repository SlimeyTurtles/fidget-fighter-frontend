//
//  UserData.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import Combine

class UserData: ObservableObject {
    @Published var spinningItem: String // What the user is spinning
    @Published var wins: Int            // Number of wins
    @Published var losses: Int          // Number of losses
    
    init(spinningItem: String = "gear", wins: Int = 0, losses: Int = 0) {
        self.spinningItem = spinningItem
        self.wins = wins
        self.losses = losses
    }
    
    func incrementWins() {
        wins += 1
    }
    
    func incrementLosses() {
        losses += 1
    }
}
