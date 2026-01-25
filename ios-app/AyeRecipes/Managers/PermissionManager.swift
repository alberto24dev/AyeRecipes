import Foundation
import Combine
import UIKit
import Photos
import AVFoundation

/// Gestor centralizado de permisos de iOS
/// Este archivo gestiona todas las solicitudes de permisos de manera lazy (bajo demanda)
/// para evitar que el sistema intente acceder a servicios innecesarios durante la inicialización
@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var photoLibraryPermissionStatus: PHAuthorizationStatus = .notDetermined
    
    private init() {
        // No solicitar permisos en la inicialización
        // Solo actualizar el estado actual
        updatePermissionStatuses()
    }
    
    // MARK: - Solicitar Permiso de Cámara (Lazy - solo cuando sea necesario)
    /// Solicita permiso de cámara SOLO cuando el usuario quiere tomar fotos
    nonisolated func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        @unknown default:
            return false
        }
    }
    
    // MARK: - Solicitar Permiso de Librería de Fotos (Lazy - solo cuando sea necesario)
    /// Solicita permiso de librería de fotos SOLO cuando el usuario quiere acceder a fotos
    nonisolated func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
        @unknown default:
            return false
        }
    }
    
    // MARK: - Actualizar Estado Actual de Permisos
    /// Solo actualiza el estado sin solicitar permisos
    private func updatePermissionStatuses() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoLibraryPermissionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    // MARK: - Abrir Configuración
    /// Abre la app de Configuración de iOS para que el usuario habilite permisos manualmente
    nonisolated func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        Task { @MainActor in
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Verificar Permisos Actuales
    nonisolated func hasCameraPermission() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    nonisolated func hasPhotoLibraryPermission() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }
}
