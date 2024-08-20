//
//  PlateDetailView.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/18.
//

import SwiftUI
import FirebaseStorage

struct PlateDetailView: View {
    @State var plate: CarPlate
    @State private var showingImagePicker = false
    @State private var image: UIImage?
    @State private var images: [UIImage] = []
    @State private var selectedImages: Set<Int> = [] // 存放被選取的照片索引
    @State private var uploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showingDeleteAlert = false
    @State private var indexToDelete: Int?

    var onSave: (CarPlate) -> Void

    var body: some View {
        VStack {
            // 顯示車牌號碼
            Text(plate.number)
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

            // 拍照按鈕
            Button(action: {
                showingImagePicker = true
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text(" 拍照")
                }
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
            .padding([.leading, .trailing], 2)
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
                    ZStack(alignment: .top) {
                        // 照片
                        NavigationLink(destination: PhotoDetailView(image: images[index], notesFileName: "\(plate.id)_notes\(index).txt")) {
                            Image(uiImage: images[index])
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor.darkGray))
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        
                        // 使用 HStack 將兩個按鈕放置在相對的兩邊
                        HStack {
                            // 選取按鈕
                            Button(action: {
                                toggleSelection(at: index)
                            }) {
                                Image(systemName: selectedImages.contains(index) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedImages.contains(index) ? .green : .white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.leading, 10)
                            
                            Spacer() // 使用 Spacer 將按鈕推到兩側
                            
                            // 刪除按鈕
                            Button(action: {
                                deleteImage(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.trailing, 10)
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .listStyle(PlainListStyle()) // 讓 List 滿版顯示

            // 上傳按鈕
            Button(action: uploadSelectedImagesToFirebase) {
                HStack {
                    Image(systemName: "cloud.upload")
                    Text("選取上傳照片")
                }
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
            .padding([.leading, .trailing], 2)

            if uploading {
                ProgressView(value: uploadProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("編輯車牌")
        .background(Color(UIColor.systemGray6))
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

    private func toggleSelection(at index: Int) {
        if selectedImages.contains(index) {
            selectedImages.remove(index)
        } else {
            selectedImages.insert(index)
        }
    }

    private func deleteImage(at index: Int) {
        indexToDelete = index
        showingDeleteAlert = true
    }

    private func deleteConfirmed(at index: Int?) {
        guard let index = index else { return }
        
        // 刪除本地圖片
        images.remove(at: index)
        deleteImageFromDisk(at: index) // 刪除磁碟上的圖片
        deleteImageFromFirebase(at: index) // 刪除 Firebase Storage 上的圖片
        saveImages() // 更新剩餘的圖片
    }

    private func deleteImageFromFirebase(at index: Int) {
        guard !plate.number.isEmpty else { return }

        let storage = Storage.storage()
        // 使用車牌號碼作為資料夾名稱
        let storageRef = storage.reference().child("plates/\(plate.number)/image\(index).jpg")

        // 開始刪除 Firebase Storage 上的圖片
        storageRef.delete { error in
            if let error = error {
                print("刪除 Firebase 圖片失敗: \(error.localizedDescription)")
            } else {
                print("成功刪除 Firebase 圖片: image\(index).jpg")
            }
        }
    }


    private func deleteImageFromDisk(at index: Int) {
        guard !plate.id.isEmpty else { return }

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryURL = documentsURL.appendingPathComponent(plate.id)
        let fileURL = directoryURL.appendingPathComponent("image\(index).jpg")

        do {
            try fileManager.removeItem(at: fileURL) // 刪除磁碟上的圖片
        } catch {
            print("刪除圖片失敗: \(error.localizedDescription)")
        }
    }

    private func saveImages() {
        guard !plate.id.isEmpty else { return }

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryURL = documentsURL.appendingPathComponent(plate.id)

        // 如果資料夾不存在，創建它
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        for (index, image) in images.enumerated() {
            if let data = image.jpegData(compressionQuality: 1.0) {
                let fileURL = directoryURL.appendingPathComponent("image\(index).jpg")
                try? data.write(to: fileURL)
            }
        }
    }

    private func loadImages() {
        guard !plate.id.isEmpty else { return }

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryURL = documentsURL.appendingPathComponent(plate.id)

        var loadedImages: [UIImage] = []
        var index = 0
        while true {
            let fileURL = directoryURL.appendingPathComponent("image\(index).jpg")
            if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                loadedImages.append(image)
                index += 1
            } else {
                break
            }
        }
        images = loadedImages
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func uploadSelectedImagesToFirebase() {
        guard !plate.id.isEmpty else { return }

        uploading = true

        let storage = Storage.storage()
        // 使用車牌號碼作為資料夾名稱
        let storageRef = storage.reference().child("plates/\(plate.number)")

        var completedUploads = 0
        let selectedImageCount = selectedImages.count

        for index in selectedImages {
            if let imageData = images[index].jpegData(compressionQuality: 0.8) {
                let imageRef = storageRef.child("image\(index).jpg")
                let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        print("上傳失敗: \(error.localizedDescription)")
                    } else {
                        print("上傳成功: image\(index).jpg")
                    }

                    completedUploads += 1

                    if completedUploads == selectedImageCount {
                        uploading = false
                        selectedImages.removeAll() // 清空選取列表
                    }
                }

                uploadTask.observe(.progress) { snapshot in
                    if let progress = snapshot.progress {
                        uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    }
                }
            }
        }
    }

}

struct PlateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlateDetailView(plate: CarPlate(id: UUID().uuidString, number: "ABC-1234"), onSave: { _ in })
        }
    }
}
