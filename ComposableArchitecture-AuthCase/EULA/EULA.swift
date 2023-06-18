//
//  EULA.swift
//  ComposableArchitecture-AuthCase
//
//  Created by Nikita Makarov on 18.06.2023.
//

import SwiftUI
import ComposableArchitecture

struct EULA: ReducerProtocol {
    
    struct State: Equatable { }
    struct Action: Equatable { }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
    
}

struct EULAView: View {
    
    let store: StoreOf<EULA>
    
    var body: some View {
        Text("EULA will be here")
    }
    
}
