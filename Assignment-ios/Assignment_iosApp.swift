//
//  Assignment_iosApp.swift
//  Assignment-ios
//
//  Created by phanindra on 30/04/26.
//

import SwiftUI
import CoreData

@main
struct Assignment_iosApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
