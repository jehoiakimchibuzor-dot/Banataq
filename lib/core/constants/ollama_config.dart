import 'package:flutter/foundation.dart';

/// Central configuration point for the local Ollama endpoint.
///
/// The base URL differs per platform, so it is never hardcoded in adapters:
/// * Windows/macOS/Linux desktop: `http://localhost:11434/v1`
/// * Android emulator: `http://10.0.2.2:11434/v1` (host loopback alias)
/// * Physical Android/iOS device: the LAN address of the development machine
///   (e.g. `http://192.168.1.20:11434/v1`) — pass it explicitly via
///   `OllamaLlmProvider(baseUrl: ...)` / `LlmProviderFactory.create(baseUrl: ...)`.
/// * Web/PWA: the browser must reach the host directly, which requires the
///   Ollama server to permit the origin (CORS) and a reachable network path.
final class OllamaConfig {
  OllamaConfig._();

  /// Model already pulled on the development machine (`ollama list`).
  static const String model = 'qwen3:1.7b';

  static const String desktopBaseUrl = 'http://localhost:11434/v1';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:11434/v1';
  static const String androidDeviceBaseUrl = 'http://10.212.86.67:11434/v1';

  /// Sensible base URL for the current platform.
  ///
  /// Android defaults to the LAN address of the development machine so real
  /// devices can reach Ollama; emulator/test setups may pass the emulator
  /// [androidEmulatorBaseUrl] explicitly.
  static String get defaultBaseUrl {
    if (kIsWeb) return desktopBaseUrl;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidDeviceBaseUrl,
      _ => desktopBaseUrl,
    };
  }
}
