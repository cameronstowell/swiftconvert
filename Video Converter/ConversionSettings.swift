//
//  ConversionSettings.swift
//  Video Converter
//
//  Created by Cameron Stowell on 1/13/26.
//


//
//  ConversionSettings.swift
//  Video Converter
//
//  Created by Cameron Stowell on 1/12/26.
//

import Foundation

struct ConversionSettings {
    var overwriteOriginal: Bool = false
    var customOutputLocation: URL? = nil
    
    var includeVideo: Bool = true
    var includeAudio: Bool = true
    var includeSubtitles: Bool = true
    
    var videoCodec: VideoCodec = .auto
    var audioCodec: AudioCodec = .auto
    
    var speedPreset: SpeedPreset = .medium
    var crf: Int = 23  // 18-28, lower = better quality
    var twoPassEncoding: Bool = false
    var customBitrate: Int? = nil  // kbps
}

enum VideoCodec: String, CaseIterable, Identifiable {
    case auto = "Auto (Smart)"
    case h264 = "H.264"
    case hevc = "H.265 (HEVC)"
    case vp9 = "VP9"
    case vp8 = "VP8"
    
    var id: String { rawValue }
    
    var ffmpegName: String {
        switch self {
        case .auto: return "auto"
        case .h264: return "libx264"
        case .hevc: return "libx265"
        case .vp9: return "libvpx-vp9"
        case .vp8: return "libvpx"
        }
    }
}

enum AudioCodec: String, CaseIterable, Identifiable {
    case auto = "Auto (Smart)"
    case aac = "AAC"
    case mp3 = "MP3"
    case opus = "Opus"
    case vorbis = "Vorbis"
    
    var id: String { rawValue }
    
    var ffmpegName: String {
        switch self {
        case .auto: return "auto"
        case .aac: return "aac"
        case .mp3: return "libmp3lame"
        case .opus: return "libopus"
        case .vorbis: return "libvorbis"
        }
    }
}

enum SpeedPreset: String, CaseIterable, Identifiable {
    case ultrafast = "Ultrafast"
    case veryfast = "Very Fast"
    case fast = "Fast"
    case medium = "Medium"
    case slow = "Slow"
    case veryslow = "Very Slow"
    
    var id: String { rawValue }
    
    var ffmpegName: String {
        switch self {
        case .ultrafast: return "ultrafast"
        case .veryfast: return "veryfast"
        case .fast: return "fast"
        case .medium: return "medium"
        case .slow: return "slow"
        case .veryslow: return "veryslow"
        }
    }
}