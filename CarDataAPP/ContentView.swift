//
//  ContentView.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/18.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import Combine

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

struct ContentView: View {
    @State private var plates: [CarPlate] = []
    @State private var isShowingAddPlateView = false
    @State private var searchText: String = ""
    @State private var isButtonHidden: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isShowingPlateDetail = false
    @State private var selectedPlate: CarPlate?

    private let db = Firestore.firestore()
    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .map { notification -> CGFloat in
                guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return 0
                }
                return value.height
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding()
                    .onChange(of: searchText) { _ in
                        hideButtonIfNeeded()
                    }
                
                if plates.isEmpty {
                    Text("沒有車牌")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(width: 250, height: 100)
                        .background(Color.gray)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 4)
                        )
                        .shadow(radius: 5)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 20) {
                            ForEach(plates.filter { $0.number.contains(searchText) || searchText.isEmpty }) { plate in
                                CarPlateView(plate: plate) {
                                    deletePlate(plate)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                if !isButtonHidden {
                    Button(action: {
                        isShowingAddPlateView = true
                    }) {
                        Text("新增車牌")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(width: 250, height: 70)
                            .background(Color.gray)
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
                }
            }
            .navigationTitle("車牌資料庫")
            .onAppear {
                loadPlates() // 在視圖顯示時加載數據
            }
            .onReceive(keyboardPublisher) { height in
                self.keyboardHeight = height
                hideButtonIfNeeded()
            }
            .gesture(
                TapGesture().onEnded {
                    hideKeyboard() // 點擊其他地方時隱藏鍵盤
                }
            )
            .sheet(isPresented: $isShowingAddPlateView) {
                AddPlateView { newPlate in
                    plates.append(newPlate)
                    savePlate(newPlate)
                    isShowingAddPlateView = false
                }
            }
            .sheet(isPresented: $isShowingPlateDetail) {
                if let plate = selectedPlate {
                    PlateDetailView(plate: plate, onSave: { updatedPlate in
                        if let index = plates.firstIndex(where: { $0.id == updatedPlate.id }) {
                            plates[index] = updatedPlate
                            savePlate(updatedPlate) // 更新 Firestore 中的車牌
                        }
                    })
                }
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

    func deletePlate(_ plate: CarPlate) {
        let plateRef = db.collection("plates").document(plate.id)
        plateRef.delete() { error in
            if let error = error {
                print("Error removing document: \(error)")
            } else {
                plates.removeAll { $0.id == plate.id }
                print("Document successfully removed!")
            }
        }
    }

    private func hideButtonIfNeeded() {
        // 隱藏按鈕條件：當鍵盤開啟或搜尋框有內容時
        isButtonHidden = searchText.isEmpty ? false : true
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CarPlateView1: View {
    let plate: CarPlate
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(plate.number)
                .font(.title)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)  // 最小縮放比例
                .lineLimit(1)
                .truncationMode(.middle)  // 中間截斷
                .padding()
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
