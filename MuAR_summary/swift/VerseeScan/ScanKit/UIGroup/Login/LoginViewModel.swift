//
//  LoginViewModel.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/6/19.
//

import Foundation
import Firebase
import SwiftUI

class LoginViewModel {
    @AppStorage("email-link") var emailLink: String?
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    
    func sendSignInLink() async {
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.url = URL(string: "https://versee.page.link/email-link-login")
        do {
            try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)
        }
        catch {
            Logger.shared.debugPrint(error.localizedDescription)
            errorMessage = error.localizedDescription
            emailLink = email
        }
    }
    
    func handleSignInLink(_ url: URL) async {
        guard let email = emailLink else {
            errorMessage = "Invalid email address."
            return
        }
        
        let link = url.absoluteString
        if Auth.auth().isSignIn(withEmailLink: link) {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, link: link)
                let user = result.user
                Logger.shared.debugPrint("User \(user.uid) signed in with email \(user.email ?? "(unkown)"). This email is \(user.isEmailVerified ? "" : "not") Verified.")
                emailLink = ""
            }
            catch {
                Logger.shared.debugPrint(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func singOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            Logger.shared.debugPrint(error)
            errorMessage = error.localizedDescription
        }
    }
}
