//
//  AuthView.swift
//  ComposableArchitecture-AuthCase
//
//  Created by Nikita Makarov on 12.06.2023.
//

import SwiftUI
import ComposableArchitecture

struct AuthView: View {
        
    var store: StoreOf<Auth>
    
    var body: some View {
        NavigationStackStore(self.store.scope(state: \.path, action: { .path($0) })) {
            WithViewStore(store, observe: { $0 }) { viewStore in
                NavigationView {
                    form(viewStore)
                        .disabled(viewStore.isSigningIn)
                        .navigationTitle("Sign In")
                }
            }
        } destination: { pathState in
            switch pathState {
            case .profile:
                CaseLet(
                    /Auth.Path.State.profile,
                     action: Auth.Path.Action.profile,
                     then: ProfileView.init(store:))
                
            case .eula:
                CaseLet(
                    /Auth.Path.State.eula,
                     action: Auth.Path.Action.eula,
                     then: EULAView.init(store:))
            }
        }
        .sheet(
            store: self.store.scope(
                state: \.$destination,
                action: { .destination($0) }),
            state: /Auth.Destination.State.eula,
            action: Auth.Destination.Action.eula,
            content: { eulaStore in
                NavigationView {
                    EULAView(store: eulaStore)
                }
            }
        )
        .sheet(
            store: self.store.scope(
                state: \.$destination,
                action: { .destination($0) }),
            state: /Auth.Destination.State.profile,
            action: Auth.Destination.Action.profile,
            content: { profileStore in
                NavigationView {
                    ProfileView(store: profileStore)
                }
            }
        )
        .alert(
            store: self.store.scope(
                state: \.$destination,
                action: { .destination($0) }),
            state: /Auth.Destination.State.signInFailedAlert,
            action: Auth.Destination.Action.signInFailedAlert
        )
    }
    
    func form(_ viewStore: ViewStoreOf<Auth>) -> some View {
        Form {
            Section {
                TextField(
                    "Username",
                    text: viewStore.binding(
                        get: \.username,
                        send: Auth.Action.usernameChanged))
                
                SecureField(
                    "Password",
                    text: viewStore.binding(
                        get: \.password,
                        send: Auth.Action.passwordChanged))
            }
            
            Section {
                if viewStore.isSigningIn {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Signing In…")
                    }
                }
                else {
                    Button("Sign In", action: {
                        viewStore.send(.signInButtonPressed)
                    })
                    .disabled(viewStore.isSignInButtonDisabled)
                }
            }
            
            Section {
                Button("Show EULA", action: {
                    viewStore.send(.showEULAButtonPressed)
                })
            }
            
            Picker(
                "Navigation Style",
                selection: viewStore.binding(
                    get: \.navigationStyle,
                    send: Auth.Action.navigationStyleChanged),
                content: {
                    ForEach(Auth.State.NavigationStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                })
        }
    }
    
}

#Preview {
    AuthView(store: .init(
        initialState: .init(),
        reducer: Auth()._printChanges()))
}
