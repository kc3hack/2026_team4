//
//  PikumeiApp.swift
//  Pikumei
//
//  Created by Sakurai Erika on 2026/02/15.
//

import SwiftData
import SwiftUI

@main
struct PikumeiApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Monster.self)
    }
}
