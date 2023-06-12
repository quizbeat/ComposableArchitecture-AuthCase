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
        
        enum NavigationStyle: String, CaseIterable {
            case modal = "Modal"
            case push = "Push"
        }
        
        var navigationStyle: NavigationStyle = .push
        
        @PresentationState
        var destination: Destination.State?
        
        var path = StackState<Profile.State>()
        
        var username: String = "borat"
        var password: String = "qwe"
        
        var isSignInButtonDisabled: Bool = true
        var isSigningIn: Bool = false
        
    }
    
    enum Action {
        
        enum SignInFailedAlert: Equatable {
            case retry
        }
        
        case navigationStyleChanged(State.NavigationStyle)
        
        case destination(PresentationAction<Destination.Action>)
        case path(StackAction<Profile.State, Profile.Action>)
        
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

                switch state.navigationStyle {
                case .modal:
                    state.destination = .modalProfile(Profile.State(profile: profile))
                    
                case .push:
                    state.path.append(Profile.State(profile: profile))
                }
                
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
                switch state.navigationStyle {
                case .modal:
                    state.destination = nil
                    
                case .push:
                    state.path.removeLast()
                }
                
                state.username = ""
                state.password = ""
                
                return .none
                
            case .destination(.presented(.signInFailedAlert(.retry))):
                return .send(.signInButtonPressed)
                
            case .path:
                return .none
                
            case .destination:
                return .none
                
            case .navigationStyleChanged(let style):
                state.navigationStyle = style
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) { Destination() }
        .forEach(\.path, action: /Action.path) { Profile() }
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
