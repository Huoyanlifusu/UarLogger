//
//  LoginSUIV.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/22.
//

import Foundation
import SwiftUI
import Firebase

class SetupHostingController: UIHostingController<LoginSUIV> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: LoginSUIV());
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

struct LoginSUIV: View {
    @AppStorage("email-link") var emailLink: String?
    @State private var isAuthenticated: Bool = false
    @State private var isLogin = false
    @State private var loginFailed = false
    @State private var emailIsIllegal = false
    @State private var loginWithEmail = false
    @State private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Spacer()
                Picker("", selection: $isLogin) {
                    Text("Log In")
                        .tag(true)
                    Text("Create Account")
                        .tag(false)
                }
                .withLoginStyles()
                .padding()
                if isLogin {
                    Picker("", selection: $loginWithEmail) {
                        Text("With Password").tag(false)
                        Text("With Email").tag(true)
                    }
                    .withLoginStyles()
                    .padding()
                }
                TextField("Email", text: $viewModel.email)
                    .withLoginStyles()
                    .padding()
                if !isLogin || (isLogin && !loginWithEmail) {
                    SecureField("Password", text: $viewModel.password)
                        .withSecureFieldStyles()
                        .padding()
                }
                Button(action: {
                    if viewModel.email.isValidEmail {
                        emailIsIllegal = false
                        if isLogin {
                            if loginWithEmail {
                                loginUserWithEmail()
                            }
                            else {
                                loginUserWithPassword()
                            }
                        }
                        else {
                            createUser()
                        }
                    } else {
                        emailIsIllegal = true
                    }
                }, label: {
                    Text(isLogin ? "Login" : "Create Account")
                        .withButtonStyles()
                })
                .withLoginStyles()
                    .alert(isPresented: $emailIsIllegal) {
                        Alert(title: Text("Warning"),
                              message: Text("Email not valid."),
                              dismissButton:.default(Text("Got it!"), action: {
                            emailIsIllegal = false
                            viewModel.email = ""
                            viewModel.password = ""
                        }))
                    }
                    .alert(isPresented: $loginFailed) {
                        Alert(title: Text("Warning"),
                              message: Text("Login failed, please check your email and password."),
                              dismissButton: .default(Text("Got it!"), action: {
                            loginFailed = false
                        }))
                    }
                Spacer()
                Text("skip ->")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .onTapGesture {
                        headToMainMenu()
                    }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: Bool.self) { isAuth in
                if isAuth {
                    MainSUIV()
                }
            }
        }.navigationTitle(isLogin ? "Welcome Back" : "Welcome")
    }
}

extension LoginSUIV {
    // https://blog.csdn.net/qq_36924683/article/details/116426160
    func headToMainMenu() {
        if let window = UIApplication.shared.windows.first {
            let setupView = MainSUIV()
            let hostingController = UIHostingController(rootView: setupView)
            // 设置动画
            hostingController.view.alpha = 0.0
            // 执行动画
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseOut], animations: {
                hostingController.view.alpha = 1.0
                window.rootViewController?.view.alpha = 0.0
            }, completion: nil)
            
            // 将 UIHostingController 设置为根视图控制器
            window.rootViewController = hostingController
            
            window.makeKeyAndVisible()
        }
    }
    
    private func loginUserWithPassword() {
        Auth.auth().signIn(withEmail: viewModel.email, password: viewModel.password) { res, err in
            if let err = err {
                Logger.shared.debugPrint("Failed to login account due to: \(err)")
                loginFailed = true
                return
            }
            Logger.shared.debugPrint("Successfully login with ID: \(res?.user.uid ?? "")")
            LoginConfig.isLogin = true
            LoginConfig.userName = viewModel.email
            headToMainMenu()
        }
    }
    
    private func loginUserWithEmail() {
        Task {
            await viewModel.sendSignInLink()
        }
    }
    
    private func createUser() {
        Auth.auth().createUser(withEmail: viewModel.email, password: viewModel.password, completion: { res, err in
            if let err = err {
                Logger.shared.debugPrint("Failed to create account due to: \(err)")
                return
            }
            Logger.shared.debugPrint("Successfully create account ID: \(res?.user.uid ?? "")")
        })
    }
}
