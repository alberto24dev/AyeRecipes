import SwiftUI

struct ContentView: View {
    // AQUÍ SE CREA EL SERVICIO UNA SOLA VEZ PARA TODA LA APP
    @StateObject private var authService = AuthService()
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // Si está autenticado, mostramos las pestañas (Tu código anterior)
                MainTabView()
                    .environmentObject(authService) // Le pasamos el servicio para poder hacer Logout después
            } else {
                // Si NO está autenticado, mostramos el Login
                LoginView(authService: authService)
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
