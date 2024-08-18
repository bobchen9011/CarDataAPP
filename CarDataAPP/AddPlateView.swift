//
//  AddPlateView.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/18.
//

import SwiftUI

struct AddPlateView: View {
    var onSave: (CarPlate) -> Void
    @State private var plateNumber: String = ""

    var body: some View {
        VStack {
            TextField("輸入車牌號碼", text: $plateNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("儲存") {
                let newPlate = CarPlate(id: UUID().uuidString, number: plateNumber)
                onSave(newPlate)
            }
            .padding()
        }
        .padding()
    }
}



