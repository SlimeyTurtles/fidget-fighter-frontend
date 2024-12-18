//
//  Global.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import Foundation

extension Notification.Name {
    static let opponentRPMUpdated = Notification.Name("opponentRPMUpdated")
    static let matchFound = Notification.Name("matchFound")
    static let gameOver = Notification.Name("gameOver")
}

struct AppConstants {
    static let webSocketURL = "ws://192.168.1.45:3000"
}
