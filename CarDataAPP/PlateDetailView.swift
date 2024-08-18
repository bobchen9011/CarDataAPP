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
    var onSave: (CarPlate) -> Void

    var body: some View {
        VStack {
            Text("編輯車牌號碼")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
                .foregroundColor(.primary)

            // 显示车牌号码
            Text(plate.number)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(width: 300, height: 100) // 调整宽高
                .background(Color.yellow)        // 背景颜色
                .cornerRadius(10)                // 圆角
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 4)  // 黑色边框
                )
                .shadow(radius: 5)                // 添加阴影
                .padding()
                .lineLimit(1)                     // 确保单行显示
                .truncationMode(.tail)            // 超出部分用省略号显示

            // 保存按钮
            Button(action: {
                onSave(plate)
            }) {
                Label(
                    title: {
                        Text("儲存")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(plate.number.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    },
                    icon: {
                        Image(systemName: "square.and.arrow.down") // 保存图标
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding(.leading, 10)
                    }
                )
            }
            .padding([.leading, .trailing], 16)
            .disabled(plate.number.isEmpty) // 按钮禁用条件

            // 拍照按钮
            Button(action: {
                showingImagePicker = true
            }) {
                Label(
                    title: {
                        Text("拍照")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    },
                    icon: {
                        Image(systemName: "camera") // 拍照图标
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding(.leading, 10)
                    }
                )
            }
            .padding([.leading, .trailing], 16)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $image)
            }

            // 显示拍摄的照片
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("編輯車牌")
        .background(Color(UIColor.systemGroupedBackground)) // 背景颜色
        .cornerRadius(20)
        .shadow(radius: 10) // 添加阴影
    }
}

struct PlateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PlateDetailView(plate: CarPlate(id: UUID().uuidString, number: "ABC-1234"), onSave: { _ in })
    }
}
