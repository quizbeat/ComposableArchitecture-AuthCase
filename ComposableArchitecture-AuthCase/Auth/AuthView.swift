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
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
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
                .disabled(viewStore.isSigningIn)
                .navigationTitle("Sign In")
            }
        }
        .sheet(
            store: self.store.scope(
                state: \.$destination,
                action: { .destination($0) }),
            state: /Auth.Destination.State.modalProfile,
            action: Auth.Destination.Action.modalProfile,
            content: { profileStore in
                NavigationView {
                    ProvfileView(store: profileStore)
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
    
}

#Preview {
    AuthView(store: .init(
        initialState: .init(),
        reducer: Auth()._printChanges()))
}
