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
    private var totalDuration: Double = 0.0
    private var startTime: Date?
    
    enum ConversionError: LocalizedError {
        case ffmpegNotFound
        case conversionFailed(String)
        case invalidInput
        case codecDetectionFailed
        
        var errorDescription: String? {
            switch self {
            case .ffmpegNotFound:
                return "ffmpeg is not installed. Please install it using: brew install ffmpeg"
            case .conversionFailed(let message):
                return "Conversion failed: \(message)"
            case .invalidInput:
                return "Invalid input file"
            case .codecDetectionFailed:
                return "Failed to detect video/audio codecs"
            }
        }
    }
    
    private static let toolPaths = [
        "ffmpeg": ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"],
        "ffprobe": ["/opt/homebrew/bin/ffprobe", "/usr/local/bin/ffprobe"]
    ]

    private func getToolPath(_ tool: String) -> String? {
        return Self.toolPaths[tool]?.first { FileManager.default.fileExists(atPath: $0) }
    }
    
    // Detect video and audio codecs
    func detectCodecs(inputURL: URL) async throws -> (videoCodec: String, audioCodec: String) {
        guard let ffprobePath = getToolPath("ffprobe") else {
            throw ConversionError.ffmpegNotFound
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ffprobePath)
            process.arguments = [
                "-v", "error",
                "-select_streams", "v:0",
                "-show_entries", "stream=codec_name",
                "-of", "default=noprint_wrappers=1:nokey=1",
                inputURL.path
            ]
            
            let videoPipe = Pipe()
            process.standardOutput = videoPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let videoData = videoPipe.fileHandleForReading.readDataToEndOfFile()
                let videoCodec = String(data: videoData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                let audioProcess = Process()
                audioProcess.executableURL = URL(fileURLWithPath: ffprobePath)
                audioProcess.arguments = [
                    "-v", "error",
                    "-select_streams", "a:0",
                    "-show_entries", "stream=codec_name",
                    "-of", "default=noprint_wrappers=1:nokey=1",
                    inputURL.path
                ]
                
                let audioPipe = Pipe()
                audioProcess.standardOutput = audioPipe
                
                try audioProcess.run()
                audioProcess.waitUntilExit()
                
                let audioData = audioPipe.fileHandleForReading.readDataToEndOfFile()
                let audioCodec = String(data: audioData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                if videoCodec.isEmpty {
                    continuation.resume(throwing: ConversionError.codecDetectionFailed)
                } else {
                    continuation.resume(returning: (videoCodec: videoCodec, audioCodec: audioCodec))
                }
            } catch {
                continuation.resume(throwing: ConversionError.codecDetectionFailed)
            }
        }
    }
    
    func convert(to format: VideoFormat) async throws {
        guard let inputURL = inputURL else {
            throw ConversionError.invalidInput
        }
        
        guard let ffmpegPath = getToolPath("ffmpeg") else {
            throw ConversionError.ffmpegNotFound
        }
        
        // Detect source codecs
        let codecs = try await detectCodecs(inputURL: inputURL)
        
        // Check what can be copied vs encoded
        let copyingVideo = format.canCopyVideo(codec: codecs.videoCodec)
        let copyingAudio = format.canCopyAudio(codec: codecs.audioCodec)
        let isFullRemux = copyingVideo && copyingAudio
        
        // Generate output URL
        let outputFileName = inputURL.deletingPathExtension().lastPathComponent + "_converted.\(format.fileExtension)"
        let outputURL = inputURL.deletingLastPathComponent().appendingPathComponent(outputFileName)
        self.outputURL = outputURL
        
        // Start conversion
        isConverting = true
        progress = 0.0
        totalDuration = 0.0
        startTime = Date()
        
        // Set appropriate status message
        if isFullRemux {
            statusMessage = "Remuxing (no encoding)..."
        } else if copyingVideo {
            statusMessage = "Copying video, encoding audio..."
        } else if copyingAudio {
            statusMessage = "Encoding video, copying audio..."
        } else {
            statusMessage = "Encoding video and audio..."
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ffmpegPath)
            
            var arguments = ["-i", inputURL.path]
            
            // Add codec arguments (copy or encode for each)
            arguments.append(contentsOf: format.getVideoCodecArgs(sourceCodec: codecs.videoCodec))
            arguments.append(contentsOf: format.getAudioCodecArgs(sourceCodec: codecs.audioCodec))
            
            arguments.append("-y")
            arguments.append(outputURL.path)
            
            process.arguments = arguments
            process.currentDirectoryURL = FileManager.default.temporaryDirectory
            
            let pipe = Pipe()
            process.standardError = pipe
            process.standardOutput = pipe
            
            // Read output for progress tracking
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let output = String(data: data, encoding: .utf8) {
                    Task { @MainActor in
                        self.parseFFmpegOutput(output, isFullRemux: isFullRemux, copyingVideo: copyingVideo, copyingAudio: copyingAudio)
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
            } catch {
                Task { @MainActor in
                    self.isConverting = false
                }
                continuation.resume(throwing: ConversionError.conversionFailed(error.localizedDescription))
            }
            
            self.conversionTask = process
        }
    }
    
    private func parseFFmpegOutput(_ output: String, isFullRemux: Bool, copyingVideo: Bool, copyingAudio: Bool) {
        // Parse duration
        if totalDuration == 0.0, let durationRange = output.range(of: "Duration: (\\d{2}):(\\d{2}):(\\d{2})\\.(\\d{2})", options: .regularExpression) {
            let durationString = String(output[durationRange])
            let components = durationString.replacingOccurrences(of: "Duration: ", with: "").split(separator: ":")
            if components.count == 3 {
                let hours = Double(components[0]) ?? 0
                let minutes = Double(components[1]) ?? 0
                let secondsAndMs = components[2].split(separator: ".")
                let seconds = Double(secondsAndMs[0]) ?? 0
                let milliseconds = secondsAndMs.count > 1 ? Double(secondsAndMs[1]) ?? 0 : 0
                
                totalDuration = (hours * 3600) + (minutes * 60) + seconds + (milliseconds / 100)
            }
        }
        
        // Parse current time
        if totalDuration > 0.0, let timeRange = output.range(of: "time=(\\d{2}):(\\d{2}):(\\d{2})\\.(\\d{2})", options: .regularExpression) {
            let timeString = String(output[timeRange])
            let components = timeString.replacingOccurrences(of: "time=", with: "").split(separator: ":")
            if components.count == 3 {
                let hours = Double(components[0]) ?? 0
                let minutes = Double(components[1]) ?? 0
                let secondsAndMs = components[2].split(separator: ".")
                let seconds = Double(secondsAndMs[0]) ?? 0
                let milliseconds = secondsAndMs.count > 1 ? Double(secondsAndMs[1]) ?? 0 : 0
                
                let currentTime = (hours * 3600) + (minutes * 60) + seconds + (milliseconds / 100)
                
                progress = min(currentTime / totalDuration, 0.99)
                
                if let startTime = startTime {
                    let elapsedTime = Date().timeIntervalSince(startTime)
                    let estimatedTotalTime = elapsedTime / progress
                    let remainingTime = estimatedTotalTime - elapsedTime
                    
                    if remainingTime > 0 {
                        let minutes = Int(remainingTime) / 60
                        let seconds = Int(remainingTime) % 60
                        
                        // Generate appropriate status message
                        let action: String
                        if isFullRemux {
                            action = "Remuxing"
                        } else if copyingVideo {
                            action = "Encoding audio"
                        } else if copyingAudio {
                            action = "Encoding video"
                        } else {
                            action = "Encoding"
                        }
                        
                        if minutes > 0 {
                            statusMessage = "\(action)... \(minutes)m \(seconds)s remaining"
                        } else {
                            statusMessage = "\(action)... \(seconds)s remaining"
                        }
                    } else {
                        if isFullRemux {
                            statusMessage = "Remuxing..."
                        } else {
                            statusMessage = "Processing..."
                        }
                    }
                }
            }
        }
    }
    
    func cancelConversion() {
        conversionTask?.terminate()
        conversionTask = nil
        isConverting = false
        statusMessage = "Cancelled"
        progress = 0.0
        
        if let outputURL = outputURL {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        self.outputURL = nil
    }
}
