import SwiftUI
import Combine

// MARK: - Image Cache Manager
/// Gestor de caché singleton para imágenes descargadas
/// Utiliza NSCache para limpieza automática bajo presión de memoria
class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let diskCacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("ImageCache")
    
    private init() {
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB limite
        cache.countLimit = 100 // Max 100 imágenes
        createDiskCacheDirectory()
    }
    
    private func createDiskCacheDirectory() {
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    // MARK: Memory Cache Operations
    func image(for key: String) -> UIImage? {
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }
        
        // Si no está en memoria, intenta disco
        return imageDiskCache(for: key)
    }
    
    func set(image: UIImage, for key: String) {
        let costInBytes = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        cache.setObject(image, forKey: key as NSString, cost: costInBytes)
        saveToDiskCache(image: image, key: key)
    }
    
    // MARK: Disk Cache Operations
    private func imageDiskCache(for key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        // Re-cargar a memoria si se encuentra en disco
        let costInBytes = data.count
        cache.setObject(image, forKey: key as NSString, cost: costInBytes)
        return image
    }
    
    private func saveToDiskCache(image: UIImage, key: String) {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return }
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
        try? jpegData.write(to: fileURL)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheURL)
        createDiskCacheDirectory()
    }
}

// MARK: - Image Downloader with Request Queue
/// Controla descargas concurrentes para evitar saturar la red y el Main Thread
class ImageDownloader {
    static let shared = ImageDownloader()
    
    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 4 // Máx 4 descargas simultáneas
        queue.qualityOfService = .userInitiated
        return queue
    }()
    
    private var activeRequests: [String: AnyCancellable] = [:]
    private let requestLock = NSLock()
    
    /// Descarga imagen con caché y límite de concurrencia
    func downloadImage(from urlString: String, completion: @escaping (UIImage?, Error?) -> Void) {
        let cacheKey = urlString
        
        // Verifica caché primero
        if let cachedImage = ImageCacheManager.shared.image(for: cacheKey) {
            completion(cachedImage, nil)
            return
        }
        
        // Evita descargas duplicadas del mismo URL
        requestLock.lock()
        if activeRequests[cacheKey] != nil {
            requestLock.unlock()
            return
        }
        requestLock.unlock()
        
        operationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            
            guard let url = URL(string: urlString) else {
                completion(nil, NSError(domain: "ImageDownloader", code: -1))
                return
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.cachePolicy = .returnCacheDataElseLoad
            
            let cancellable = URLSession.shared.dataTaskPublisher(for: request)
                .tryMap { data, response in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NSError(domain: "ImageDownloader", code: -1)
                    }
                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw NSError(domain: "ImageDownloader", code: httpResponse.statusCode)
                    }
                    guard let image = UIImage(data: data) else {
                        throw NSError(domain: "ImageDownloader", code: -2)
                    }
                    return image
                }
                .receive(on: DispatchQueue.main) // IMPORTANTE: Solo el callback en Main Thread
                .sink { [weak self] completionResult in
                    self?.requestLock.lock()
                    self?.activeRequests.removeValue(forKey: cacheKey)
                    self?.requestLock.unlock()
                    
                    switch completionResult {
                    case .failure(let error):
                        completion(nil, error)
                    case .finished:
                        break
                    }
                } receiveValue: { (image: UIImage) in
                    // Cachea la imagen
                    ImageCacheManager.shared.set(image: image, for: cacheKey)
                    completion(image, nil)
                }
            
            self.requestLock.lock()
            self.activeRequests[cacheKey] = cancellable
            self.requestLock.unlock()
        }
    }
}

// MARK: - ImageLoader with Lazy Loading Support
@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: String?
    
    private var downloadTask: Cancellable?
    private let urlString: String?
    
    init(url: String? = nil) {
        self.urlString = url
    }
    
    func load(from urlString: String?) {
        guard let urlString = urlString, !urlString.isEmpty else {
            self.image = nil
            self.error = "Invalid URL"
            return
        }
        
        // Si ya está cargada, no hacer nada
        if image != nil {
            return
        }
        
        isLoading = true
        error = nil
        
        ImageDownloader.shared.downloadImage(from: urlString) { [weak self] image, error in
            Task { @MainActor in
                self?.isLoading = false
                if let image = image {
                    self?.image = image
                } else {
                    self?.error = error?.localizedDescription ?? "Unknown error"
                }
            }
        }
    }
    
    deinit {
        downloadTask?.cancel()
    }
}

// MARK: - RemoteImage View with Lazy Loading
struct RemoteImage: View {
    let url: String?
    @StateObject private var loader = ImageLoader()
    
    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
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

// MARK: - LazyLoadingList Helper
/// Componente auxiliar para implementar lazy loading en listas
struct LazyLoadingModifier: ViewModifier {
    let url: String?
    let onAppear: (String?) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                onAppear(url)
            }
    }
}

extension View {
    func loadImageLazy(url: String?, onAppear: @escaping (String?) -> Void) -> some View {
        modifier(LazyLoadingModifier(url: url, onAppear: onAppear))
    }
}

#Preview {
    RemoteImage(url: nil)
}
