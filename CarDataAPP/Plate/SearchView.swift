//
//  SearchView.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/19.
//

import SwiftUI

struct SearchBar: UIViewRepresentable {
    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            let formattedText = formatPlateNumber(searchText)
            text = formattedText
            searchBar.text = formattedText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

        private func formatPlateNumber(_ input: String) -> String {
            // 移除非字母和數字的字符
            let filteredInput = input.uppercased().filter { $0.isLetter || $0.isNumber }
            
            // 限制最多輸入三個字母
            let letters = filteredInput.prefix(3)
            
            // 限制最多輸入四個數字
            let numbers = filteredInput.dropFirst(3).prefix(4)

            // 格式化輸入為 'ABC-1234'
            var result = String(letters)
            if !numbers.isEmpty {
                result += "-" + numbers
            }
            return result
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "搜尋車牌號碼 (ABC-1234)"
        searchBar.autocapitalizationType = .allCharacters
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}
