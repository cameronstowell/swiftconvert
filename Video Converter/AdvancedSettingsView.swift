//
//  AdvancedSettingsView.swift
//  Video Converter
//
//  Created by Cameron Stowell on 1/13/26.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @Binding var isExpanded: Bool
    @Binding var settings: ConversionSettings
    let inputURL: URL
    
    // Add selectedFormat as a parameter to AdvancedSettingsView
    let selectedFormat: VideoFormat

    private func isVideoCodecCompatible(codec: VideoCodec, format: VideoFormat) -> Bool {
        
        switch (codec, format) {
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

    private func isAudioCodecCompatible(codec: AudioCodec, format: VideoFormat) -> Bool {
        switch (codec, format) {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header button
            Button(action: { 
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Advanced")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Overwrite original
                    Toggle("Overwrite original file", isOn: $settings.overwriteOriginal)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 13))
                    
                    // Output location
                    if !settings.overwriteOriginal {
                        HStack {
                            Text("Output Location:")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            
                            Button(settings.customOutputLocation?.lastPathComponent ?? "Same as input") {
                                selectOutputLocation()
                            }
                            .font(.system(size: 13))
                            
                            if settings.customOutputLocation != nil {
                                Button(action: { settings.customOutputLocation = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Stream inclusion
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Toggle("Include Video", isOn: $settings.includeVideo)
                                .toggleStyle(.checkbox)
                            
                            Spacer()
                            
                            if settings.includeVideo {
                                Picker("", selection: $settings.videoCodec) {
                                    ForEach(VideoCodec.allCases.filter { codec in
                                        codec == .auto || isVideoCodecCompatible(codec: codec, format: selectedFormat)
                                    }) { codec in
                                        Text(codec.rawValue).tag(codec)
                                    }
                                }
                                .frame(width: 150)
                            }
                        }
                        .font(.system(size: 13))
                        
                        HStack {
                            Toggle("Include Audio", isOn: $settings.includeAudio)
                                .toggleStyle(.checkbox)
                            
                            Spacer()
                            
                            if settings.includeAudio {
                                Picker("", selection: $settings.audioCodec) {
                                    ForEach(AudioCodec.allCases.filter { codec in
                                        codec == .auto || isAudioCodecCompatible(codec: codec, format: selectedFormat)
                                    }) { codec in
                                        Text(codec.rawValue).tag(codec)
                                    }
                                }
                                .frame(width: 150)
                            }
                        }
                        .font(.system(size: 13))
                        
                        Toggle("Include Subtitles", isOn: $settings.includeSubtitles)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 13))
                    }
                    
                    Divider()
                    
                    // Speed preset
                    HStack {
                        Text("Speed Preset:")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $settings.speedPreset) {
                            ForEach(SpeedPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .frame(width: 150)
                    }
                    
                    // CRF slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Quality (CRF):")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text("\(settings.crf)")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Text("Lower = Better")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(settings.crf) },
                            set: { settings.crf = Int($0) }
                        ), in: 18...28, step: 1)
                    }
                    
                    // Two-pass encoding
                    Toggle("Two-pass encoding (slower, better quality)", isOn: $settings.twoPassEncoding)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 13))
                    
                    // Bitrate
                    HStack {
                        Text("Bitrate (optional):")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        
                        TextField("Auto", value: $settings.customBitrate, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        
                        Text("kbps")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    private func selectOutputLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.directoryURL = inputURL.deletingLastPathComponent()
        
        if panel.runModal() == .OK {
            settings.customOutputLocation = panel.url
        }
    }
}
