//
//  PhotoDetailView.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/19.
//

import SwiftUI

struct PhotoDetailView: View {
    var image: UIImage
    @State private var notes: String = ""
    var notesFileName: String // 從 PlateDetailView 傳入筆記檔案名稱

    var body: some View {
        VStack {
            // 顯示圖片
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 4)
                    )
            }
            .padding()

            // 筆記區域
            Text("維修紀錄")
                .font(.headline)
                .padding(.top)
            
            TextEditor(text: $notes)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .frame(height: 150)
                .padding([.leading, .trailing])

            Spacer()
        }
        .padding()
        .navigationTitle("編輯照片")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground)) // 背景顏色
        .onAppear(perform: loadNotes)
        .onChange(of: notes, perform: { newValue in
            saveNotes()
        })
        .onTapGesture {
            hideKeyboard()
        }
    }

    // 儲存筆記到應用的文檔目錄
    private func saveNotes() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let notesURL = documentsURL.appendingPathComponent(notesFileName)
        try? notes.write(to: notesURL, atomically: true, encoding: .utf8)
    }

    // 從應用的文檔目錄加載筆記
    private func loadNotes() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let notesURL = documentsURL.appendingPathComponent(notesFileName)
        if let loadedNotes = try? String(contentsOf: notesURL, encoding: .utf8) {
            notes = loadedNotes
        }
    }

    // 隱藏鍵盤的功能
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoDetailView(image: UIImage(systemName: "photo")!, notesFileName: "notes.txt")
    }
}
