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
            
            if filteredInput.count == 7 {
                // 格式化為 3英文-4數字
                let letters = filteredInput.prefix(3)
                let numbers = filteredInput.suffix(4)
                return "\(letters)-\(numbers)"
            } else if filteredInput.count == 6 {
                // 格式化為 3英文-3數字 或 2英文-3數字 或 4數字-2英文 或 3數字-3英文
                let prefix = filteredInput.prefix(3)
                let suffix = filteredInput.suffix(3)
                
                if prefix.allSatisfy({ $0.isLetter }) && suffix.allSatisfy({ $0.isNumber }) {
                    return "\(prefix)-\(suffix)"
                } else if prefix.prefix(2).allSatisfy({ $0.isLetter }) && suffix.allSatisfy({ $0.isNumber }) {
                    return "\(prefix.prefix(2))-\(suffix)"
                } else if prefix.allSatisfy({ $0.isNumber }) && suffix.allSatisfy({ $0.isLetter }) {
                    return "\(prefix)-\(suffix)"
                } else if prefix.suffix(2).allSatisfy({ $0.isLetter }) && prefix.prefix(4).allSatisfy({ $0.isNumber }) {
                    return "\(prefix.prefix(4))-\(prefix.suffix(2))"
                }
            } else if filteredInput.count == 5 {
                // 格式化為 3英文-2數字 或 2英文-3數字
                let prefix = filteredInput.prefix(3)
                let suffix = filteredInput.suffix(2)
                
                if prefix.prefix(3).allSatisfy({ $0.isLetter }) && suffix.allSatisfy({ $0.isNumber }) {
                    return "\(prefix)-\(suffix)"
                } else if prefix.prefix(2).allSatisfy({ $0.isLetter }) && suffix.allSatisfy({ $0.isNumber }) {
                    return "\(prefix.prefix(2))-\(suffix)"
                }
            }
            return filteredInput
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "搜尋車牌號碼"
        searchBar.autocapitalizationType = .allCharacters
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}
