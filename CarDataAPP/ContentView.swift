//
//  ContentView.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/18.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

struct ContentView: View {
    @State private var plates: [CarPlate] = []
    @State private var isShowingAddPlateView = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                if plates.isEmpty {
                    Text("沒有車牌")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(width: 250, height: 100)
                        .background(Color.yellow)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 4)
                        )
                        .shadow(radius: 5)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                            ForEach(plates) { plate in
                                NavigationLink(destination: PlateDetailView(plate: plate, onSave: { updatedPlate in
                                    if let index = plates.firstIndex(where: { $0.id == updatedPlate.id }) {
                                        plates[index] = updatedPlate
                                        savePlate(updatedPlate) // 更新 Firestore 中的車牌
                                    }
                                })) {
                                    CarPlateView(plate: plate)
                                }
                            }
                        }
                        .padding()
                    }
                }

                Spacer()
                
                Button(action: {
                    isShowingAddPlateView = true
                }) {
                    Text("新增車牌")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(width: 350, height: 100) // 調整寬高
                        .background(Color.yellow)        // 背景顏色
                        .cornerRadius(10)                // 圓角
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 4)  // 黑色邊框
                        )
                        .shadow(radius: 5)                // 添加陰影
                        .padding()
                        .lineLimit(1)                     // 確保單行顯示
                        .truncationMode(.tail)
                }
                .padding()
                .sheet(isPresented: $isShowingAddPlateView) {
                    AddPlateView { newPlate in
                        plates.append(newPlate)
                        savePlate(newPlate)
                        isShowingAddPlateView = false
                    }
                }
            }
            .navigationTitle("車牌資料庫")
            .onAppear {
                loadPlates() // 在視圖顯示時加載數據
            }
        }
    }

    func savePlate(_ plate: CarPlate) {
        let plateRef = db.collection("plates").document(plate.id)
        plateRef.setData([
            "number": plate.number
        ]) { error in
            if let error = error {
                print("Error writing document: \(error)")
            } else {
                print("Document successfully written!")
            }
        }
    }

    func loadPlates() {
        db.collection("plates").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                var loadedPlates: [CarPlate] = querySnapshot?.documents.compactMap { document -> CarPlate? in
                    let data = document.data()
                    guard let number = data["number"] as? String else { return nil }
                    return CarPlate(id: document.documentID, number: number)
                } ?? []
                
                // 對車牌號碼進行排序
                loadedPlates.sort { $0.number.localizedStandardCompare($1.number) == .orderedAscending }
                
                plates = loadedPlates
            }
        }
    }
}

struct CarPlateView: View {
    let plate: CarPlate

    var body: some View {
        Text(plate.number)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.black)
            .frame(width: 200, height: 100) // 調整寬高
            .background(Color.yellow)        // 背景顏色
            .cornerRadius(10)                // 圓角
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 4)  // 黑色邊框
            )
            .shadow(radius: 5)                // 添加陰影
            .padding()
            .lineLimit(1)                     // 確保單行顯示
            .truncationMode(.tail)            // 超出部分用省略號顯示
    }
}

#Preview(body: {
    ContentView()
})
