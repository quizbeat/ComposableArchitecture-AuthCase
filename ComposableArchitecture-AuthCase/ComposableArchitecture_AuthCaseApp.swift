//
//  ComposableArchitecture_AuthCaseApp.swift
//  ComposableArchitecture-AuthCase
//
//  Created by Nikita Makarov on 12.06.2023.
//

import SwiftUI

@main
struct ComposableArchitecture_AuthCaseApp: App {
    
    var body: some Scene {
        WindowGroup {
            AuthView(store: .init(
                initialState: .init(),
                reducer: Auth()._printChanges()))
        }
    }
    
}
