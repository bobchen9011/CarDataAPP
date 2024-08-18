//
//  CarDataAPPApp.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/18.
//

import SwiftUI

@main
struct CarDataAPPApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
