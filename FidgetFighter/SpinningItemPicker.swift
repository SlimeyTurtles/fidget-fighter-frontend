//
//  SpinningItemPicker.swift
//  FidgetFighter
//
//  Created by Avinh Huynh on 12/17/24.
//

import SwiftUI

struct SpinningItemPicker: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss

    // Available items with their images and names
    let items = [
        (name: "Gear", image: "gear"),
        (name: "Circle", image: "circle"),
        (name: "Star", image: "star"),
        (name: "Leaf", image: "leaf")
    ]

    let columns = [ // Define grid layout
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(items, id: \.name) { item in
                        Button(action: {
                            userData.spinningItem = item.image // Update selected spinning item
                            dismiss() // Dismiss picker
                        }) {
                            VStack {
                                Image(systemName: item.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.blue)

                                Text(item.name)
                                    .font(.headline)
                                    .foregroundColor(userData.spinningItem == item.image ? .blue : .black)
                            }
                            .padding()
                            .background(Color(.green).edgesIgnoringSafeArea(.all))
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Item")
            .navigationBarItems(trailing: Button("Close") {
                dismiss() // Close picker
            })
        }
    }
}
