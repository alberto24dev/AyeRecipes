import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellable: AnyCancellable?
    
    func load(from urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            self.image = nil
            self.error = "Invalid URL"
            return
        }
        
        isLoading = true
        error = nil
        
        print("🖼️ Intentando cargar imagen desde: \(urlString)")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "ImageLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    print("❌ Status code: \(httpResponse.statusCode)")
                    throw NSError(domain: "ImageLoader", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
                }
                
                guard let image = UIImage(data: data) else {
                    throw NSError(domain: "ImageLoader", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not decode image"])
                }
                
                return image
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ Error cargando imagen: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                case .finished:
                    print("✅ Imagen cargada exitosamente")
                }
            } receiveValue: { [weak self] image in
                self?.image = image
            }
    }
    
    deinit {
        cancellable?.cancel()
    }
}

struct RemoteImage: View {
    let url: String?
    @StateObject private var loader = ImageLoader()
    
    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if loader.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
            } else {
                // Placeholder cuando no hay imagen
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(red: 1.0, green: 0.27, blue: 0.0).opacity(0.2))
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundStyle(.orange)
                        }
                    }
            }
        }
        .onAppear {
            loader.load(from: url)
        }
    }
}

#Preview {
    RemoteImage(url: nil)
}
