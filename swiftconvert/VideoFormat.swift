//
//  VideoFormat.swift
//  Video Converter
//
//  Created by Cameron Stowell on 1/12/26.
//
import Foundation

enum VideoFormat: String, CaseIterable {
    case mp4 = "mp4"
    case mov = "mov"
    case mkv = "mkv"
    case webm = "webm"
    case avi = "avi"
    
    var displayName: String {
        rawValue.uppercased()
    }
    
    var fileExtension: String {
        rawValue
    }
    
    // Supported video codecs for each container format
    var supportedVideoCodecs: [String] {
        switch self {
        case .mp4:
            return ["h264", "hevc", "mpeg4", "avc", "avc1"]
        case .mov:
            return ["h264", "hevc", "prores", "mpeg4", "avc", "avc1"]
        case .mkv:
            return ["h264", "hevc", "vp9", "vp8", "av1", "mpeg4", "avc", "avc1"]
        case .webm:
            return ["vp9", "vp8"]
        case .avi:
            return ["h264", "mpeg4", "avc", "avc1"]
        }
    }
    
    // Supported audio codecs for each container format
    var supportedAudioCodecs: [String] {
        switch self {
        case .mp4:
            return ["aac", "mp3"]
        case .mov:
            return ["aac", "mp3", "pcm", "pcm_s16le"]
        case .mkv:
            return ["aac", "mp3", "opus", "vorbis", "flac", "pcm", "pcm_s16le"]
        case .webm:
            return ["opus", "vorbis"]
        case .avi:
            return ["aac", "mp3"]
        }
    }
    
    // Check if video codec is compatible (can be copied)
    func canCopyVideo(codec: String) -> Bool {
        let normalized = codec.lowercased()
        return supportedVideoCodecs.contains(normalized)
    }
    
    // Check if audio codec is compatible (can be copied)
    func canCopyAudio(codec: String) -> Bool {
        let normalized = codec.lowercased()
        return supportedAudioCodecs.contains(normalized)
    }
    
    // Get video codec arguments (copy if compatible, encode if not)
    func getVideoCodecArgs(sourceCodec: String) -> [String] {
        if canCopyVideo(codec: sourceCodec) {
            return ["-c:v", "copy"]
        } else {
            return videoEncodeArgs
        }
    }
    
    // Get audio codec arguments (copy if compatible, encode if not)
    func getAudioCodecArgs(sourceCodec: String) -> [String] {
        if canCopyAudio(codec: sourceCodec) {
            return ["-c:a", "copy"]
        } else {
            return audioEncodeArgs
        }
    }
    
    // Default video encoding arguments for this format
    private var videoEncodeArgs: [String] {
        switch self {
        case .mp4, .mov, .mkv, .avi:
            return ["-c:v", "libx264", "-preset", "medium", "-crf", "23"]
        case .webm:
            return ["-c:v", "libvpx-vp9", "-crf", "30", "-b:v", "0"]
        }
    }
    
    // Default audio encoding arguments for this format
    private var audioEncodeArgs: [String] {
        switch self {
        case .mp4, .mov, .mkv, .avi:
            return ["-c:a", "aac"]
        case .webm:
            return ["-c:a", "libopus"]
        }
    }
}
