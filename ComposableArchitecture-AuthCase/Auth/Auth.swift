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
        
        var path = StackState<Path.State>()
        
        var username: String = "borat"
        var password: String = "qwe"
        
        var isSignInButtonDisabled: Bool = false
        var isSigningIn: Bool = false
        
    }
    
    enum Action {
        
        enum SignInFailedAlert: Equatable {
            case retry
        }
                
        case navigationStyleChanged(State.NavigationStyle)
        
        // Modal Navigation (Sheets, Alerts)
        case destination(PresentationAction<Destination.Action>)
        
        // Push Navigation (Navigation Stack)
        case path(StackAction<Path.State, Path.Action>)
        
        case usernameChanged(String)
        case passwordChanged(String)
        case signInButtonPressed

        case showEULAButtonPressed
        
        case signInSucceeded(UserProfile)
        case signInFailed
        
    }
    
    @Dependency(\.authService) var authService
    
    var body: some ReducerProtocolOf<Self> {
        Reduce { state, action in
            switch action {
            case .usernameChanged(let username):
                state.username = username
                state.isSignInButtonDisabled = state.hasEmptyCredential
                return.none
                
            case .passwordChanged(let password):
                state.password = password
                state.isSignInButtonDisabled = state.hasEmptyCredential
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
                
            case .showEULAButtonPressed:
                let eula = EULA.State()
                switch state.navigationStyle {
                case .modal:
                    state.destination = .eula(eula)
                    
                case .push:
                    state.path.append(.eula(eula))
                }
                return .none
                
            case .signInSucceeded(let profile):
                state.isSigningIn = false

                let profile = Profile.State(profile: profile)
                
                switch state.navigationStyle {
                case .modal:
                    state.destination = .profile(profile)
                    
                case .push:
                    state.path.append(.profile(profile))
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
                
            // Modal Navigation - Sign Out Handling
            case .destination(.presented(.profile(.listener(.signOut)))):
                state.clearCredentials()
                state.destination = nil
                return .none
            
            // Modal Navigation - Alert Action Handling
            case .destination(.presented(.signInFailedAlert(.retry))):
                return .send(.signInButtonPressed)
                
            // Push Navigation
            case .path(let pathAction):
                switch pathAction {
                // Sign Out Handling
                case .element(id: let id, action: .profile(.listener(.signOut))):
                    state.clearCredentials()
                    state.path.pop(from: id)
                
                // Tap/Gesture Pop Handling
                case .popFrom(let id):
                    print("pop from \(id)")
                    
                default:
                    break
                }

                return .none
                
            case .destination:
                return .none
                
            case .navigationStyleChanged(let style):
                state.navigationStyle = style
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) { Destination() }
        .forEach(\.path, action: /Action.path) { Path() }
    }
    
}

extension Auth {
    
    struct Destination: ReducerProtocol {
        
        enum State: Equatable {
            
            case eula(EULA.State)
            case profile(Profile.State)
            case signInFailedAlert(AlertState<Auth.Action.SignInFailedAlert>)
            
        }
        
        enum Action {
            
            case eula(EULA.Action)
            case profile(Profile.Action)
            case signInFailedAlert(Auth.Action.SignInFailedAlert)
            
        }
        
        var body: some ReducerProtocolOf<Self> {
            Scope(state: /State.eula, action: /Action.eula) { EULA() }
            Scope(state: /State.profile, action: /Action.profile) { Profile() }
        }
        
    }
    
}

extension Auth {
    
    struct Path: ReducerProtocol {
        
        enum State: Equatable {
            case profile(Profile.State)
            case eula(EULA.State)
        }
        
        enum Action: Equatable {
            case profile(Profile.Action)
            case eula(EULA.Action)
        }
        
        var body: some ReducerProtocolOf<Self> {
            Scope(state: /State.eula , action: /Action.eula) { EULA() }
            Scope(state: /State.profile , action: /Action.profile) { Profile() }
        }
        
    }
    
}

extension Auth.State {
    
    mutating func clearCredentials() {
        username = ""
        password = ""
    }
    
    var hasEmptyCredential: Bool {
        username.isEmpty || password.isEmpty
    }
    
}
