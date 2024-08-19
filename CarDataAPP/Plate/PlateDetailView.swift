//
//  PlateDetailView.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/18.
//

import SwiftUI

struct PlateDetailView: View {
    @State var plate: CarPlate
    @State private var showingImagePicker = false
    @State private var image: UIImage?
    @State private var images: [UIImage] = []
    var onSave: (CarPlate) -> Void

    var body: some View {
        VStack {
            // 顯示車牌號碼
            Text(plate.number)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(width: 250, height: 70)
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

            // 拍照按鈕
            Button(action: {
                showingImagePicker = true
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("拍照")
                }
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
            .padding([.leading, .trailing], 16)
            .sheet(isPresented: $showingImagePicker, onDismiss: {
                if let image = image {
                    images.append(image)
                    saveImages()
                }
            }) {
                ImagePicker(selectedImage: $image)
            }

            // 顯示拍攝的照片列表
            ScrollView {
                ForEach(images.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        // 照片
                        NavigationLink(destination: PhotoDetailView(image: images[index], notesFileName: "notes\(index).txt")) {
                            Image(uiImage: images[index])
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }

                        // 刪除按鈕
                        Button(action: {
                            // 彈出確認刪除的 alert
                            deleteImage(at: index)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.trailing, 10)
                        .padding(.top, 10)
                    }
                }
            }
            .listStyle(PlainListStyle()) // 讓 List 滿版顯示
            .padding([.leading, .trailing])

            Spacer()
        }
        .padding()
        .navigationTitle("編輯車牌")
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .onAppear(perform: loadImages)
        .onTapGesture {
            hideKeyboard()
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("確定刪除照片嗎？"),
                primaryButton: .destructive(Text("刪除")) {
                    deleteConfirmed(at: indexToDelete)
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }

    @State private var showingDeleteAlert = false
    @State private var indexToDelete: Int?

    // 確認刪除前彈出 alert
    private func deleteImage(at index: Int) {
        indexToDelete = index
        showingDeleteAlert = true
    }

    // 確認刪除操作
    private func deleteConfirmed(at index: Int?) {
        guard let index = index else { return }
        images.remove(at: index)
        saveImages()
    }

    // 儲存圖片到應用的文檔目錄
    private func saveImages() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for (index, image) in images.enumerated() {
            if let data = image.jpegData(compressionQuality: 1.0) {
                let fileURL = documentsURL.appendingPathComponent("image\(index).jpg")
                try? data.write(to: fileURL)
            }
        }
    }

    // 從應用的文檔目錄加載圖片
    private func loadImages() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var loadedImages: [UIImage] = []
        var index = 0
        while true {
            let fileURL = documentsURL.appendingPathComponent("image\(index).jpg")
            if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                loadedImages.append(image)
                index += 1
            } else {
                break
            }
        }
        images = loadedImages
    }

    // 隱藏鍵盤的功能
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PlateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlateDetailView(plate: CarPlate(id: UUID().uuidString, number: "ABC-1234"), onSave: { _ in })
        }
    }
}
