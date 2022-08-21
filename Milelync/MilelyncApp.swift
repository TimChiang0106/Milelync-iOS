//
//  MilelyncApp.swift
//  Milelync
//
//  Created by Tim Chiang on 2022/8/21.
//

import SwiftUI

@main
struct MilelyncApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(network)
        }
    }
}
