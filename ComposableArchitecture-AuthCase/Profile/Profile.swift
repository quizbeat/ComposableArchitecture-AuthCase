//
//  Profile.swift
//  ComposableArchitecture-AuthCase
//
//  Created by Nikita Makarov on 12.06.2023.
//

import Foundation
import ComposableArchitecture

struct Profile: ReducerProtocol {
    
    struct State: Equatable {
        
        @PresentationState
        var signOutConfirmationAlert: AlertState<Action.SignOutConfirmationAlert>?
        
        let profile: UserProfile
        
    }
    
    enum Action {
        
        enum SignOutConfirmationAlert {
            case confirm
        }
        
        enum Listener {
            case signOut
        }
        
        case signOutButtonPressed
        case signOutConfirmationAlert(PresentationAction<SignOutConfirmationAlert>)
        case listener(Listener)
        
    }
    
    var body: some ReducerProtocolOf<Self> {
        Reduce { state, action in
            switch action {
            case .signOutButtonPressed:
                state.signOutConfirmationAlert = AlertState {
                    TextState("Confirm Sign Out")
                } actions: {
                    ButtonState(role: .destructive, action: .send(.confirm)) {
                        TextState("Definitely")
                    }
                } message: {
                    TextState("Are you sure you want to sign out?")
                }
                return .none
                
            case .signOutConfirmationAlert(.presented(.confirm)):
                return .send(.listener(.signOut))
                
            case .signOutConfirmationAlert:
                return .none
                
            case .listener:
                return .none
            }
        }
        .ifLet(\.signOutConfirmationAlert, action: /Action.signOutConfirmationAlert)
    }
    
}
