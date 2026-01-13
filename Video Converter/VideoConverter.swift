//
//  VideoConverter.swift
//  Video Converter
//
//  Created by Cameron Stowell on 1/12/26.
//
import Foundation
import Combine

@MainActor
class VideoConverter: ObservableObject {
    @Published var inputURL: URL?
    @Published var outputURL: URL?
    @Published var isConverting = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var showSuccess = false
    
    private var conversionTask: Process?
    
    enum ConversionError: LocalizedError {
        case ffmpegNotFound
        case conversionFailed(String)
        case invalidInput
        
        var errorDescription: String? {
            switch self {
            case .ffmpegNotFound:
                return "ffmpeg is not installed. Please install it using: brew install ffmpeg"
            case .conversionFailed(let message):
                return "Conversion failed: \(message)"
            case .invalidInput:
                return "Invalid input file"
            }
        }
    }
    
    // Check if ffmpeg is installed
    func checkFFmpeg() -> Bool {
        let ffmpegPaths = [
            "/opt/homebrew/bin/ffmpeg",  // Apple Silicon
            "/usr/local/bin/ffmpeg"       // Intel
        ]
        
        return ffmpegPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }
    
    // Get ffmpeg path
    func getFFmpegPath() -> String? {
        let ffmpegPaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg"
        ]
        
        return ffmpegPaths.first { FileManager.default.fileExists(atPath: $0) }
    }
    
    func convert(to format: VideoFormat) async throws {
        guard let inputURL = inputURL else {
            throw ConversionError.invalidInput
        }
        
        // Check for ffmpeg
        guard checkFFmpeg(), let ffmpegPath = getFFmpegPath() else {
            throw ConversionError.ffmpegNotFound
        }
        
        // Generate output URL
        let outputFileName = inputURL.deletingPathExtension().lastPathComponent + "_converted.\(format.fileExtension)"
        let outputURL = inputURL.deletingLastPathComponent().appendingPathComponent(outputFileName)
        self.outputURL = outputURL
        
        // Start conversion
        isConverting = true
        progress = 0.0
        statusMessage = "Starting conversion..."
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ffmpegPath)
            
            var arguments = ["-i", inputURL.path]
            arguments.append(contentsOf: format.ffmpegArgs)
            arguments.append("-y")
            arguments.append(outputURL.path)
            
            process.arguments = arguments
            process.currentDirectoryURL = FileManager.default.temporaryDirectory
            
            let pipe = Pipe()
            process.standardError = pipe
            process.standardOutput = pipe
            
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let output = String(data: data, encoding: .utf8) {
                    Task { @MainActor in
                        self.parseFFmpegOutput(output)
                    }
                }
            }
            
            process.terminationHandler = { process in
                Task { @MainActor in
                    self.isConverting = false
                    
                    if process.terminationStatus == 0 {
                        self.statusMessage = "Conversion complete!"
                        self.progress = 1.0
                        self.showSuccess = true
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: ConversionError.conversionFailed("Process exited with code \(process.terminationStatus)"))
                    }
                }
            }
            
            do {
                try process.run()
                self.conversionTask = process
            } catch {
                Task { @MainActor in
                    self.isConverting = false
                }
                continuation.resume(throwing: ConversionError.conversionFailed(error.localizedDescription))
            }
        }
    }
    
    private func parseFFmpegOutput(_ output: String) {
        // Simple progress parsing - look for "time=" in ffmpeg output
        // This is a basic implementation; real parsing would extract duration first
        if output.contains("time=") {
            // Extract time from output (format: time=00:01:23.45)
            if let timeRange = output.range(of: "time=\\d{2}:\\d{2}:\\d{2}\\.\\d{2}", options: .regularExpression) {
                let timeString = String(output[timeRange]).replacingOccurrences(of: "time=", with: "")
                statusMessage = "Converting... \(timeString)"
                
                // Rough progress estimation (this would need duration info for accuracy)
                if progress < 0.95 {
                    progress += 0.01
                }
            }
        }
    }
    
    func cancelConversion() {
        conversionTask?.terminate()
        conversionTask = nil
        isConverting = false
        statusMessage = "Cancelled"
    }
}
