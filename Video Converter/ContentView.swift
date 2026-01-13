//
//  ContentView.swift
//  Video Converter
//
//  Created by Cameron Stowell on 1/12/26.
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
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(nsColor: .controlBackgroundColor),
                    Color(nsColor: .controlBackgroundColor).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with extra spacing
                VStack(spacing: 8) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.tint)
                        .symbolEffect(.bounce, value: converter.inputURL)
                    
                    Text("Video Converter")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                }
                .padding(.top, 40)
                .padding(.bottom, 32)
                
                // Drop Zone with liquid glass effect
                ZStack {
                    // Glass card background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: isDragging ?
                                            [Color.accentColor.opacity(0.5), Color.accentColor.opacity(0.2)] :
                                            [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
                    
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(isDragging ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "video.badge.plus")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(isDragging ? Color.accentColor : Color.secondary)
                                .symbolEffect(.pulse, value: isDragging)
                        }
                        
                        VStack(spacing: 6) {
                            Text("Drop video here")
                                .font(.system(size: 17, weight: .medium))
                            
                            Text("or click to browse")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(50)
                }
                .frame(height: 220)
                .padding(.horizontal, 40)
                .scaleEffect(isDragging ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                    handleDrop(providers: providers)
                    return true
                }
                .onTapGesture {
                    selectFile()
                }
                
                // Selected File Card
                if let inputURL = converter.inputURL {
                    VStack(spacing: 16) {
                        // File info
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentColor.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.tint)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(inputURL.lastPathComponent)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                                
                                Text("Ready to convert")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Format selector
                        HStack {
                            Text("Output format")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Picker("", selection: $selectedFormat) {
                                ForEach(VideoFormat.allCases, id: \.self) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Progress indicator
                if converter.isConverting {
                    HStack(spacing: 12) {
                        VStack(spacing: 12) {
                            ProgressView(value: converter.progress)
                                .tint(.accentColor)
                            
                            Text(converter.statusMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        // Cancel button
                        Button(action: {
                            converter.cancelConversion()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.red, .red.opacity(0.2))
                        }
                        .buttonStyle(.plain)
                        .help("Cancel conversion")
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Convert button
                Button(action: startConversion) {
                    HStack(spacing: 8) {
                        if converter.isConverting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(converter.isConverting ? "Converting..." : "Convert Video")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        ZStack {
                            if converter.inputURL != nil && !converter.isConverting {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentColor)
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: isHoveringButton ?
                                                [Color.white.opacity(0.2), Color.clear] :
                                                [Color.clear, Color.clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.2))
                            }
                        }
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .disabled(converter.inputURL == nil || converter.isConverting)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
                .scaleEffect(isHoveringButton && converter.inputURL != nil ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHoveringButton)
                .onHover { hovering in
                    isHoveringButton = hovering
                }
            }
        }
        .frame(width: 540, height: 640)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success!", isPresented: $converter.showSuccess) {
            Button("OK", role: .cancel) { }
            Button("Show in Finder") {
                if let outputURL = converter.outputURL {
                    NSWorkspace.shared.selectFile(outputURL.path, inFileViewerRootedAtPath: "")
                }
            }
        } message: {
            Text("Video converted successfully!")
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
                try await converter.convert(to: selectedFormat)
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
