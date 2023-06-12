//
//  Auth.swift
//  ComposableArchitecture-AuthCase
//
//  Created by Nikita Makarov on 12.06.2023.
//

import UIKit
import ComposableArchitecture

struct Auth: ReducerProtocol {
    
    struct State: Equatable {
        
        @PresentationState
        var destination: Destination.State?
        
        var username: String = ""
        var password: String = ""
        
        var isSignInButtonDisabled: Bool = true
        var isSigningIn: Bool = false
        
        var profile: UserProfile? = nil
        var path = StackState<Profile.State>()
        
    }
    
    enum Action {
        
        enum SignInFailedAlert: Equatable {
            case retry
        }
        
        case destination(PresentationAction<Destination.Action>)
        
        case usernameChanged(String)
        case passwordChanged(String)
        case signInButtonPressed
        
        case signInSucceeded(UserProfile)
        case signInFailed
        
    }
    
    @Dependency(\.authService) var authService
    
    var body: some ReducerProtocolOf<Self> {
        Reduce { state, action in
            switch action {
            case .usernameChanged(let username):
                state.username = username
                state.isSignInButtonDisabled = (state.username.isEmpty || state.password.isEmpty)
                return.none
                
            case .passwordChanged(let password):
                state.password = password
                state.isSignInButtonDisabled = (state.username.isEmpty || state.password.isEmpty)
                return .none
                
            case .signInButtonPressed:
                state.isSigningIn = true
                return .run { [username = state.username, password = state.password] send in
                    do {
                        let profile = try await authService.signIn(
                            username: username, password: password)
                        await send(.signInSucceeded(profile))
                    }
                    catch AuthService.Error.invalidCredentials {
                        await send(.signInFailed)
                    }
                }
                
            case .signInSucceeded(let profile):
                state.isSigningIn = false
                state.profile = profile
                
                // Modal Presentation
                state.destination = .modalProfile(
                    Profile.State(profile: profile))
                
                // Navigation Stack
                
                return .none
                
            case .signInFailed:
                state.isSigningIn = false
                state.destination = .signInFailedAlert(
                    AlertState {
                        TextState("Invalid Credentials")
                    } actions: {
                        ButtonState(role: .cancel, action: .send(.none)) {
                            TextState("Cancel")
                        }
                        ButtonState(action: .send(.retry)) {
                            TextState("Retry")
                        }
                    }
                )
                return .none
                
            case .destination(.presented(.modalProfile(.listener(.signOut)))):
                state.destination = nil
                state.username = ""
                state.password = ""
                state.profile = nil
                return .none
                
            case .destination(.presented(.signInFailedAlert(.retry))):
                return .send(.signInButtonPressed)
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) { Destination() }
    }
    
}

extension Auth {
    
    struct Destination: ReducerProtocol {
        
        enum State: Equatable {
            
            case modalProfile(Profile.State)
            case signInFailedAlert(AlertState<Auth.Action.SignInFailedAlert>)
            
        }
        
        enum Action {
            
            case modalProfile(Profile.Action)
            case signInFailedAlert(Auth.Action.SignInFailedAlert)
            
        }
        
        var body: some ReducerProtocolOf<Self> {
            Scope(state: /State.modalProfile, action: /Action.modalProfile) { Profile() }
        }
        
    }
    
}
