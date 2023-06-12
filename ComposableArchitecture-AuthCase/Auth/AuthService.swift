//
//  AuthService.swift
//  ComposableArchitecture-AuthCase
//
//  Created by Nikita Makarov on 12.06.2023.
//

import UIKit
import ComposableArchitecture

struct UserProfile: Equatable {
    
    let firstName: String
    let lastName: String
    let avatar: UIImage
    
}

class AuthService {
    
    enum Error: Swift.Error {
        case invalidCredentials
    }
    
    func signIn(username: String, password: String) async throws -> UserProfile {
        try await Task.sleep(for: .seconds(2), clock: .continuous)
        
        guard username == "borat" && password == "qwe" else {
            throw Error.invalidCredentials
        }
        
        return UserProfile(
            firstName: "Borat",
            lastName: "Sagdiyev",
            avatar: .borat)
    }
    
}

extension AuthService: DependencyKey {
    
    static var liveValue: AuthService = {
        .init()
    }()
    
}

extension AuthService: TestDependencyKey {
    
    static var testValue: AuthService = {
        .init()
    }()
    
}

extension DependencyValues {
    
    var authService: AuthService {
        get { self[AuthService.self] }
        set { self[AuthService.self] = newValue }
    }

}
