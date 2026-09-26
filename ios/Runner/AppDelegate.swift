import Flutter
import UIKit
import Vision
import ImageIO

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VaultOfflineOCR") else { return }
    let channel = FlutterMethodChannel(name: "document_vault/offline_ocr", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize" else { result(FlutterMethodNotImplemented); return }
      guard let args = call.arguments as? [String: Any],
            let bytes = args["bytes"] as? FlutterStandardTypedData,
            bytes.data.count <= 20 * 1024 * 1024 else {
        result(FlutterError(code: "invalid_image", message: "Choose an image up to 20 MB.", details: nil)); return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let request = VNRecognizeTextRequest()
          request.recognitionLevel = .accurate
          request.recognitionLanguages = ["en-US"]
          request.usesLanguageCorrection = true
          guard let source = CGImageSourceCreateWithData(bytes.data as CFData, nil),
                let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: 2400
                ] as CFDictionary) else { throw NSError(domain: "VaultOCR", code: 1) }
          let handler = VNImageRequestHandler(cgImage: image, options: [:])
          try handler.perform([request])
          let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
          DispatchQueue.main.async { result(text) }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "ocr_failed", message: "Could not read this image.", details: nil)) }
        }
      }
    }
  }
}
