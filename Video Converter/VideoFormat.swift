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
    
    // Basic ffmpeg encoding arguments for each format
    var ffmpegArgs: [String] {
        switch self {
        case .mp4:
            return ["-c:v", "libx264", "-preset", "medium", "-crf", "23", "-c:a", "aac"]
        case .mov:
            return ["-c:v", "libx264", "-preset", "medium", "-crf", "23", "-c:a", "aac"]
        case .mkv:
            return ["-c:v", "libx264", "-preset", "medium", "-crf", "23", "-c:a", "aac"]
        case .webm:
            return ["-c:v", "libvpx-vp9", "-crf", "30", "-b:v", "0", "-c:a", "libopus"]
        case .avi:
            return ["-c:v", "libx264", "-preset", "medium", "-crf", "23", "-c:a", "aac"]
        }
    }
}
