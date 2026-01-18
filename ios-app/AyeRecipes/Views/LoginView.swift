import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var name = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("AyeRecipes")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Picker("Mode", selection: $isSignUp.animation()) {
                            Text("Log In").tag(false)
                            Text("Sign Up").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal, 40)
                        .padding(.top, 4)
                        .onAppear {
                            UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.orange
                            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
                        }
                    }
                    .padding(.top, 32)
                    
                    // Formulario
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Email", systemImage: "envelope")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.3), lineWidth: 1.5))
                        }
                        
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Name", systemImage: "person")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                                TextField("Your name", text: $name)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.3), lineWidth: 1.5))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Password", systemImage: "lock")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)
                            SecureField("Minimum 6 characters", text: $password)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.3), lineWidth: 1.5))
                        }
                        
                        // Mensajes
                        if let error = authService.errorMessage {
                            Text(error).foregroundColor(.red).font(.caption)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Botón
                    Button(action: {
                        Task {
                            if isSignUp { await authService.register(email: email, password: password, name: name) }
                            else { await authService.login(email: email, password: password) }
                        }
                    }) {
                        if authService.isLoading { ProgressView().tint(.white) }
                        else {
                            Text(isSignUp ? "Sign Up" : "Log In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 24)
                    .disabled(authService.isLoading)
                    
                    Spacer()
                }
            }
        }
    }
}
