import Foundation
@preconcurrency import CoreHaptics
import Combine
import SwiftUI
import os.log
import AVFoundation

/// Gestor centralizado de feedback háptico con ciclo de vida seguro
/// Previene crashes XPC del servicio com.apple.audio.hapticd
@MainActor
final class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    // MARK: - Properties
    
    /// Referencia única al motor háptico - NUNCA se recrea
    /// Se mantiene viva durante toda la sesión de la app
    private var engine: CHHapticEngine?
    
    /// Flag para rastrear si el motor está listo
    @Published private(set) var isAvailable = false
    @Published private(set) var isEngineRunning = false
    
    private let logger = Logger(subsystem: "com.ayerecipes.haptic", category: "HapticManager")
    
    /// Cola serializada para operaciones de haptic
    private let hapticQueue = DispatchQueue(label: "com.ayerecipes.haptic.queue", qos: .userInteractive)
    
    // MARK: - Inicialización
    
    private init() {
        prepareHapticEngine()
    }
    
    // MARK: - Engine Preparation (Una sola vez)
    
    /// Prepara el motor háptico UNA SOLA VEZ
    /// Esto se ejecuta al inicializar el singleton
    private func prepareHapticEngine() {
        // 1. Verificar disponibilidad de hardware
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            logger.warning("Haptic feedback no soportado en este dispositivo")
            isAvailable = false
            return
        }
        
        // 2. CRÍTICO: Configurar AVAudioSession ANTES de crear el motor
        // Esto previene que AVCaptureSession silencie los haptics
        configureAudioSession()
        
        // 3. Crear el motor - SOLO UNA OCASIÓN
        do {
            engine = try CHHapticEngine()
            isAvailable = true
            logger.info("CHHapticEngine creado exitosamente")
        } catch {
            logger.error("Error creando CHHapticEngine: \(error.localizedDescription)")
            isAvailable = false
            return
        }
        
        // 3. Configurar callbacks para reconectar si se desconecta
        setupEngineCallbacks()
        
        // 4. Iniciar el motor de forma lazy
        // NO lo iniciamos aquí, lo hacemos solo cuando se necesita
    }
    
    // MARK: - Audio Session Configuration
    
    /// Configura la sesión de audio para coexistir con AVCaptureSession
    /// CRÍTICO: Debe ejecutarse ANTES de inicializar CHHapticEngine
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Configurar categoría .ambient para permitir mezcla con otros audios/haptics
            // .mixWithOthers permite que la cámara y los haptics funcionen simultáneamente
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            logger.info("✅ AVAudioSession configurada para coexistencia con cámara")
        } catch {
            logger.error("❌ Error configurando AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Engine Callbacks
    
    /// Configura handlers para reconectarse automáticamente si el servicio falla
    private func setupEngineCallbacks() {
        guard let engine = engine else { return }
        
        // Reset handler: se ejecuta cuando el motor se resetea inesperadamente
        engine.resetHandler = { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.warning("⚠️  CHHapticEngine fue resetado - reconectando...")
                self.reconnectEngine()
            }
        }
        
        // Stopped handler: se ejecuta cuando el motor se detiene (ej: por la cámara)
        // CRÍTICO: Reinicia automáticamente el motor para recuperar funcionalidad
        engine.stoppedHandler = { [weak self] reason in
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.warning("⚠️  CHHapticEngine se detuvo. Razón: \(reason.rawValue)")
                self.isEngineRunning = false
                
                // Si se detuvo por causa del sistema (1 = System Error / Audio Session Preemption)
                // intentar reiniciar automáticamente después de un pequeño delay
                if reason == .systemError || reason == .audioSessionInterrupt {
                    self.logger.info("🔄 Intentando reiniciar motor háptico...")
                    Task {
                        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 segundos
                        await MainActor.run {
                            self.startEngine()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Engine Lifecycle Management
    
    /// Inicia el motor háptico de forma segura (idempotente)
    private func startEngine() {
        guard let engine = engine, !isEngineRunning else { return }
        
        do {
            try engine.start()
            isEngineRunning = true
            logger.info("✅ CHHapticEngine iniciado")
        } catch {
            logger.error("❌ Error iniciando CHHapticEngine: \(error.localizedDescription)")
            isEngineRunning = false
        }
    }
    
    /// Detiene el motor háptico de forma segura
    private func stopEngine() {
        guard let engine = engine, isEngineRunning else { return }
        
        engine.stop { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                self?.isEngineRunning = false
                if let error = error {
                    self?.logger.error("❌ Error deteniendo CHHapticEngine: \(error.localizedDescription)")
                } else {
                    self?.logger.info("✅ CHHapticEngine detenido")
                }
            }
        }
    }
    
    /// Reconecta el motor si se desconectó del servicio XPC
    private func reconnectEngine() {
        Task { @MainActor in
            self.stopEngine()
            
            // Pequeño delay antes de reconectar
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            self.startEngine()
        }
    }
    
    // MARK: - Haptic Feedback Generation
    
    /// FUNCIÓN DE PRUEBA: Dispara un patrón háptico fuerte para verificar funcionamiento
    /// Útil para confirmar físicamente que el motor háptico está operativo
    public func triggerTestHaptic() {
        Task { @MainActor in
            self.generateTestHaptic()
        }
    }
    
    private func generateTestHaptic() {
        guard isAvailable, let engine = engine else {
            logger.error("❌ Motor háptico no disponible para prueba")
            return
        }
        
        // Asegurar que el motor está iniciado
        startEngine()
        
        do {
            // Crear un patrón fuerte e inconfundible:
            // 1. Pulso intenso inicial
            // 2. Dos pulsos medios
            // 3. Pulso intenso final
            let events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: 0.0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: 0.15
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: 0.3
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: 0.5
                )
            ]
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            
            logger.info("✅ TEST: Patrón háptico de prueba disparado (deberías sentir 4 vibraciones)")
        } catch {
            logger.error("❌ Error generando haptic de prueba: \(error.localizedDescription)")
        }
    }
    
    /// Genera feedback háptico simple
    /// - Parameter intensity: Intensidad de 0.0 a 1.0
    public func playSimpleFeedback(intensity: Float = 1.0) {
        Task { @MainActor in
            self.generateSimpleFeedback(intensity: intensity)
        }
    }
    
    private func generateSimpleFeedback(intensity: Float) {
        guard isAvailable, let engine = engine else { return }
        
        // Asegurar que el motor está iniciado
        startEngine()
        
        do {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: min(1.0, max(0.0, intensity)))
                ],
                relativeTime: 0.0
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            
            logger.debug("✅ Feedback háptico simple generado")
        } catch {
            logger.error("❌ Error generando feedback háptico: \(error.localizedDescription)")
        }
    }
    
    /// Genera un patrón háptico personalizado
    /// - Parameters:
    ///   - events: Array de eventos hápticos
    public func playPattern(events: [CHHapticEvent]) {
        Task { @MainActor in
            self.generatePattern(events: events)
        }
    }
    
    private func generatePattern(events: [CHHapticEvent]) {
        guard isAvailable, let engine = engine else { return }
        
        startEngine()
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            
            logger.debug("✅ Patrón háptico personalizado generado")
        } catch {
            logger.error("❌ Error generando patrón háptico: \(error.localizedDescription)")
        }
    }
    
    /// Genera feedback de "éxito" (3 pulsos pequeños)
    public func playSuccess() {
        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
            ], relativeTime: 0.0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            ], relativeTime: 0.1),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
            ], relativeTime: 0.2),
        ]
        playPattern(events: events)
    }
    
    /// Genera feedback de "error" (vibración de baja frecuencia)
    public func playError() {
        guard isAvailable, let engine = engine else { return }
        
        startEngine()
        
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.0,
                duration: 0.15
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            
            logger.debug("✅ Feedback de error generado")
        } catch {
            logger.error("❌ Error generando feedback de error: \(error.localizedDescription)")
        }
    }
    
    /// Genera feedback de "selección" (vibración ligera)
    public func playSelection() {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            ],
            relativeTime: 0.0
        )
        playPattern(events: [event])
    }
    
    // MARK: - Cleanup
    
    deinit {
        // El engine se libera automáticamente cuando se destruye HapticManager
        // No es necesario hacer cleanup explícito en deinit
    }
}

// MARK: - Extensiones convenientes para usar en SwiftUI

extension View {
    /// Modifier para reproducir feedback háptico en una acción
    func hapticFeedback(_ type: HapticFeedbackType) -> some View {
        self.onTapGesture {
            HapticManager.shared.playSimpleFeedback()
        }
    }
}

enum HapticFeedbackType {
    case selection
    case success
    case error
    case impact
}
