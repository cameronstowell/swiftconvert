//
//  ContentView.swift
//  Video Converter
//
//  Compact horizontal layout with Auto/Manual modes
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var converter = VideoConverter()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedFormat: VideoFormat = .mp4
    @State private var isDragging = false
    @State private var isHoveringButton = false
    @State private var settingsMode: SettingsMode = .auto
    @State private var settings = ConversionSettings()
    
    enum SettingsMode: String, CaseIterable {
        case auto = "Auto"
        case manual = "Manual"
    }
    
    var body: some View {
        ZStack {
            Color(nsColor: .controlBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                Text("Video Converter")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                
                // Main content
                HStack(spacing: 0) {
                    // Left - Drop zone
                    VStack(spacing: 0) {
                        if converter.inputURL == nil {
                            // Drop zone
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        isDragging ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2),
                                        lineWidth: 2,
                                        antialiased: true
                                    )
                                
                                VStack(spacing: 12) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 40, weight: .thin))
                                        .foregroundStyle(isDragging ? Color.accentColor : Color.secondary)
                                    
                                    Text("Drop video to convert")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 360, height: 280)
                            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                                handleDrop(providers: providers)
                                return true
                            }
                            .onTapGesture {
                                selectFile()
                            }
                        } else {
                            // File info
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(converter.inputURL!.lastPathComponent)
                                        .font(.system(size: 14, weight: .medium))
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    Button(action: { converter.inputURL = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Text("Ready to convert")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.tertiary)
                                
                                Spacer()
                            }
                            .frame(width: 320, height: 240)
                            .padding(20)
                            .background(Color.secondary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(width: 360)
                    .padding(.leading, 24)
                    
                    // Right - Settings
                    VStack(alignment: .center, spacing: 16) {
                        // Mode picker
                        Picker("", selection: $settingsMode) {
                            ForEach(SettingsMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        
                        Divider()
                        
                        // Format
                        HStack(spacing: 12) {
                            Text("Format")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .leading)
                            
                            Picker("", selection: $selectedFormat) {
                                ForEach(VideoFormat.allCases, id: \.self) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .frame(width: 140)
                        }
                        
                        // Speed preset
                        HStack(spacing: 12) {
                            Text("Speed")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .leading)
                            
                            Picker("", selection: $settings.speedPreset) {
                                ForEach(SpeedPreset.allCases) { preset in
                                    Text(preset.rawValue).tag(preset)
                                }
                            }
                            .frame(width: 140)
                        }
                        
                        // Quality slider
                        // Quality preset
                        HStack(spacing: 12) {
                            Text("Quality")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .leading)
                            
                            Picker("", selection: $settings.qualityPreset) {
                                ForEach(QualityPreset.allCases) { preset in
                                    Text(preset.rawValue).tag(preset)
                                }
                            }
                            .frame(width: 140)
                        }
                        
                        // Manual mode settings
                        if settingsMode == .manual {
                            Divider()
                            
                            // Overwrite + Output location
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Overwrite original", isOn: $settings.overwriteOriginal)
                                    .toggleStyle(.checkbox)
                                    .font(.system(size: 12))
                                
                                if !settings.overwriteOriginal {
                                    HStack {
                                        Text("Output:")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                        
                                        Button(action: selectOutputLocation) {
                                            HStack(spacing: 4) {
                                                Text(settings.customOutputLocation?.lastPathComponent ?? "Same as input")
                                                    .font(.system(size: 12))
                                                    .lineLimit(1)
                                                Image(systemName: "folder")
                                                    .font(.system(size: 11))
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Video + Audio codecs
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Video")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.tertiary)
                                    
                                    Picker("", selection: $settings.videoCodec) {
                                        ForEach(VideoCodec.allCases.filter { codec in
                                            codec == .auto || isVideoCodecCompatible(codec: codec)
                                        }) { codec in
                                            Text(codec.rawValue).tag(codec)
                                        }
                                    }
                                    .frame(width: 110)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Audio")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.tertiary)
                                    
                                    Picker("", selection: $settings.audioCodec) {
                                        ForEach(AudioCodec.allCases.filter { codec in
                                            codec == .auto || isAudioCodecCompatible(codec: codec)
                                        }) { codec in
                                            Text(codec.rawValue).tag(codec)
                                        }
                                    }
                                    .frame(width: 110)
                                }
                            }
                            
                            // Include checkboxes
                            HStack(spacing: 16) {
                                Toggle("Video", isOn: $settings.includeVideo)
                                    .toggleStyle(.checkbox)
                                    .font(.system(size: 12))
                                
                                Toggle("Audio", isOn: $settings.includeAudio)
                                    .toggleStyle(.checkbox)
                                    .font(.system(size: 12))
                                
                                Toggle("Subs", isOn: $settings.includeSubtitles)
                                    .toggleStyle(.checkbox)
                                    .font(.system(size: 12))
                            }
                            
                            // Two-pass + Bitrate
                            HStack(spacing: 12) {
                                Toggle("Two-pass", isOn: $settings.twoPassEncoding)
                                    .toggleStyle(.checkbox)
                                    .font(.system(size: 12))
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("Bitrate:")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.tertiary)
                                    
                                    TextField("", value: $settings.customBitrate, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 50)
                                        .font(.system(size: 11))
                                    
                                    Text("kbps")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(width: 300)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
                
                // Bottom - Progress and button
                VStack(spacing: 12) {
                    if converter.isConverting {
                        HStack(spacing: 10) {
                            VStack(spacing: 6) {
                                ProgressView(value: converter.progress)
                                    .tint(.accentColor)
                                
                                Text(converter.statusMessage)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button(action: { converter.cancelConversion() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Button(action: startConversion) {
                        Text("Convert")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                converter.inputURL != nil && !converter.isConverting ?
                                    Color.accentColor : Color.secondary.opacity(0.2)
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(converter.inputURL == nil || converter.isConverting)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(width: 700, height: 600)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success!", isPresented: $converter.showSuccess) {
            Button("OK", role: .cancel) { }
            Button("Show in Finder") {
                if let outputURL = converter.outputURL {
                    NSWorkspace.shared.selectFile(outputURL.path(), inFileViewerRootedAtPath: "")
                }
            }
        } message: {
            Text("Video converted successfully!")
        }
    }
    
    private func isVideoCodecCompatible(codec: VideoCodec) -> Bool {
        switch (codec, selectedFormat) {
        case (.h264, .mp4), (.h264, .mov), (.h264, .mkv), (.h264, .avi):
            return true
        case (.hevc, .mp4), (.hevc, .mov), (.hevc, .mkv):
            return true
        case (.vp9, .mkv), (.vp9, .webm):
            return true
        case (.vp8, .mkv), (.vp8, .webm):
            return true
        default:
            return false
        }
    }
    
    private func isAudioCodecCompatible(codec: AudioCodec) -> Bool {
        switch (codec, selectedFormat) {
        case (.aac, .mp4), (.aac, .mov), (.aac, .mkv), (.aac, .avi):
            return true
        case (.mp3, .mp4), (.mp3, .mov), (.mp3, .mkv), (.mp3, .avi):
            return true
        case (.opus, .mkv), (.opus, .webm):
            return true
        case (.vorbis, .mkv), (.vorbis, .webm):
            return true
        default:
            return false
        }
    }
    
    private func selectOutputLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        if let inputURL = converter.inputURL {
            panel.directoryURL = inputURL.deletingLastPathComponent()
        }
        
        if panel.runModal() == .OK {
            settings.customOutputLocation = panel.url
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (data, error) in
            if let data = data as? Data,
               let path = String(data: data, encoding: .utf8),
               let url = URL(string: path) {
                DispatchQueue.main.async {
                    self.converter.inputURL = url
                }
            }
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .video, .mpeg4Movie, .quickTimeMovie, .avi]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            converter.inputURL = url
        }
    }
    
    private func startConversion() {
        Task {
            do {
                try await converter.convert(to: selectedFormat, settings: settings)
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
