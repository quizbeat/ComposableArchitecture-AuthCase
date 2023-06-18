//
//  ProvfileView.swift
//  ComposableArchitecture-AuthCase
//
//  Created by Nikita Makarov on 12.06.2023.
//

import SwiftUI
import ComposableArchitecture

struct ProfileView: View {
    
    let store: StoreOf<Profile>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section(content: {
                    HStack {
                        Text("First Name")
                        Spacer()
                        Text(viewStore.profile.firstName)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Last Name")
                        Spacer()
                        Text(viewStore.profile.lastName)
                            .foregroundStyle(.secondary)
                    }
                }, header: {
                    VStack {
                        HStack(alignment: .center) {
                            Spacer()
                            Image(uiImage: viewStore.profile.avatar)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                            Spacer()
                        }
                        Spacer()
                            .frame(height: 24)
                    }
                })
                
                Button("Sign Out") {
                    viewStore.send(.signOutButtonPressed)
                }
                .foregroundStyle(.red)
            }
            .navigationTitle("Profile")
        }
        .alert(store: self.store.scope(
            state: \.$signOutConfirmationAlert,
            action: { .signOutConfirmationAlert($0) }))
    }
    
}

#Preview {
    ProfileView(store: .init(
        initialState: .init(
            profile: UserProfile(
                firstName: "Borat",
                lastName: "Sagdiyev",
                avatar: .borat)),
        reducer: Profile()))
}
