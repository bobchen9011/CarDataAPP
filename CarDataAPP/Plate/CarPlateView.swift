//
//  CarPlateView.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/19.
//

import SwiftUI

struct CarPlateView: View {
    let plate: CarPlate
    var onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack {
            NavigationLink(destination: PlateDetailView(plate: plate, onSave: { updatedPlate in
                // 這裡不需要處理編輯回調，因為導航會處理更新
            })) {
                Text(plate.number)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(width: 200, height: 100)
                    .background(Color.yellow)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 4)
                    )
                    .shadow(radius: 5)
                    .padding()
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            // 刪除按鈕
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("確定刪除"),
                    message: Text("您確定要刪除這個車牌嗎？"),
                    primaryButton: .destructive(Text("刪除")) {
                        onDelete()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
    }
}
