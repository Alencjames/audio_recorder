import Foundation
import AVFoundation

enum FilterCategory: String, CaseIterable {
    case all = "All"
    case shared = "Shared"
    case starred = "Starred"
}

class AudioViewModel: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    // MARK: - Multicast State Observer System for UIKit (Decoupled from Combine/SwiftUI)
    private var stateChangeCallbacks: [String: () -> Void] = [:]
    
    // Fast path UI update callbacks
    var onRecordingTimeChanged: ((TimeInterval) -> Void)?
    var onAudioSamplesChanged: (([CGFloat]) -> Void)?
    
    func addStateChangeObserver(identifier: String, callback: @escaping () -> Void) {
        stateChangeCallbacks[identifier] = callback
        callback() // Trigger initial update immediately
    }
    
    func removeStateChangeObserver(identifier: String) {
        stateChangeCallbacks.removeValue(forKey: identifier)
    }
    
    private func notifyStateChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stateChangeCallbacks.values.forEach { $0() }
        }
    }
    
    // MARK: - View Model State Properties
    var recordings: [Recording] = [] {
        didSet { notifyStateChanged() }
    }
    
    // Filter State
    var searchQuery: String = "" {
        didSet { notifyStateChanged() }
    }
    var selectedFilter: FilterCategory = .all {
        didSet { notifyStateChanged() }
    }
    var selectedDate: Date? {
        didSet { notifyStateChanged() }
    }
    
    // Recording State
    var isRecording = false {
        didSet { notifyStateChanged() }
    }
    var isRecordingPaused = false {
        didSet { notifyStateChanged() }
    }
    var recordingTime: TimeInterval = 0 {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onRecordingTimeChanged?(self.recordingTime)
            }
        }
    }
    var audioSamples: [CGFloat] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onAudioSamplesChanged?(self.audioSamples)
            }
        }
    }
    
    // Playback State
    var isPlaying = false {
        didSet { notifyStateChanged() }
    }
    var playingURL: URL? {
        didSet { notifyStateChanged() }
    }
    var playbackTime: TimeInterval = 0 {
        didSet { notifyStateChanged() }
    }
    var playbackProgress: Double = 0.0 {
        didSet { notifyStateChanged() }
    }
    var currentPlaybackLevel: Float = 0.0 {
        didSet { notifyStateChanged() }
    }
    
    // Computed Filtered Recordings
    var filteredRecordings: [Recording] {
        var filtered = recordings
        
        if selectedFilter == .shared {
            filtered = filtered.filter { $0.isShared }
        } else if selectedFilter == .starred {
            filtered = filtered.filter { $0.isStarred }
        }
        
        if let filterDate = selectedDate {
            filtered = filtered.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: filterDate) }
        }
        
        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
        }
        
        return filtered
    }
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var playbackTimer: Timer?
    private let sampleCount = 50
    
    override init() {
        super.init()
        fetchRecordings()
    }
    
    // MARK: - Permissions
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            if !allowed {
                print("Microphone permission denied.")
            }
        }
    }
    
    // MARK: - Recording
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func pauseResumeRecording() {
        guard let recorder = audioRecorder else { return }
        if isRecordingPaused {
            recorder.record()
            isRecordingPaused = false
            startTimer()
        } else {
            recorder.pause()
            isRecordingPaused = true
            timer?.invalidate()
        }
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dateString = ISO8601DateFormatter().string(from: Date())
            let audioFilename = documentPath.appendingPathComponent("Recording-\(dateString).m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            isRecordingPaused = false
            recordingTime = 0
            audioSamples = Array(repeating: 0, count: sampleCount)
            
            startTimer()
            
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
            stopRecording()
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        isRecordingPaused = false
        timer?.invalidate()
        fetchRecordings()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }
            
            recorder.updateMeters()
            self.recordingTime = recorder.currentTime
            
            let level = recorder.averagePower(forChannel: 0)
            let normalizedLevel = self.normalizeSoundLevel(level: level)
            
            self.audioSamples.removeFirst()
            self.audioSamples.append(normalizedLevel)
        }
    }
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.2, CGFloat(level) + 50) / 2
        return CGFloat(level)
    }
    
    // MARK: - Playback
    func playPause(recording: Recording) {
        if isPlaying && playingURL == recording.fileURL {
            pausePlayback()
        } else if playingURL == recording.fileURL {
            resumePlayback()
        } else {
            startPlayback(url: recording.fileURL)
        }
    }
    
    private func startPlayback(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.play()
            
            isPlaying = true
            playingURL = url
            playbackTime = 0
            playbackProgress = 0.0
            currentPlaybackLevel = 0.0
            
            startPlaybackTimer()
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }
    
    private func resumePlayback() {
        audioPlayer?.isMeteringEnabled = true
        audioPlayer?.play()
        isPlaying = true
        startPlaybackTimer()
    }
    
    private func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        stopPlaybackTimer()
    }
    
    func seekPlayback(to progress: Double) {
        guard let player = audioPlayer else { return }
        let newTime = player.duration * progress
        player.currentTime = newTime
        playbackTime = newTime
        playbackProgress = progress
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        // Poll at 25 fps (0.04s) for high fidelity real-time levels
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer, player.isPlaying else { return }
            self.playbackTime = player.currentTime
            self.playbackProgress = player.currentTime / player.duration
            
            player.updateMeters()
            let power = player.averagePower(forChannel: 0)
            
            // Logarithmic mapping for better visual matching of perceived volume!
            let linearPower = pow(10.0, Double(power) / 20.0) // Ranges from 0.0 to 1.0
            
            // Scale and clamp the linear value to get a highly prominent waveform during speech
            let scaledLevel = Float(min(1.0, linearPower * 2.8))
            self.currentPlaybackLevel = scaledLevel
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        currentPlaybackLevel = 0.0
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopPlaybackTimer()
        playbackTime = player.duration
        playbackProgress = 1.0
        currentPlaybackLevel = 0.0
    }
    
    // MARK: - File Management
    private func fetchRecordings() {
        recordings.removeAll()
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            
            let supportedExtensions = ["m4a", "mp3", "wav", "caf"]
            for url in directoryContents {
                if supportedExtensions.contains(url.pathExtension.lowercased()) {
                    let creationDate = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
                    let duration = getDuration(for: url)
                    
                    var title = url.deletingPathExtension().lastPathComponent
                    if title.hasPrefix("Recording-") {
                        title = "Recording \(creationDate.formatted(date: .abbreviated, time: .omitted))"
                    }
                    
                    // Restore saved title colour and star status
                    let colorKey = "titleColor_\(url.lastPathComponent)"
                    let savedHex = UserDefaults.standard.string(forKey: colorKey)
                    
                    let starKey = "isStarred_\(url.lastPathComponent)"
                    let isStarred = UserDefaults.standard.bool(forKey: starKey)
                    
                    let shareKey = "isShared_\(url.lastPathComponent)"
                    let isShared = UserDefaults.standard.bool(forKey: shareKey)
                    
                    var recording = Recording(fileURL: url, createdAt: creationDate, duration: duration, title: title)
                    recording.titleColorHex = savedHex
                    recording.isStarred = isStarred
                    recording.isShared = isShared
                    recordings.append(recording)
                }
            }
            recordings.sort(by: { $0.createdAt > $1.createdAt })
        } catch {
            print("Failed to fetch recordings: \(error.localizedDescription)")
        }
    }
    
    private func getDuration(for url: URL) -> TimeInterval {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            return audioPlayer.duration
        } catch {
            return 0
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        do {
            try FileManager.default.removeItem(at: recording.fileURL)
            if playingURL == recording.fileURL {
                stopPlayback()
            }
            fetchRecordings()
        } catch {
            print("Failed to delete recording: \(error.localizedDescription)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        playingURL = nil
        stopPlaybackTimer()
    }
    
    func toggleStar(for recording: Recording) {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index].isStarred.toggle()
            let starKey = "isStarred_\(recording.fileURL.lastPathComponent)"
            UserDefaults.standard.set(recordings[index].isStarred, forKey: starKey)
        }
    }
    
    // MARK: - Title Colour
    func setTitleColor(hex: String?, for recording: Recording) {
        guard let index = recordings.firstIndex(where: { $0.id == recording.id }) else { return }
        let colorKey = "titleColor_\(recording.fileURL.lastPathComponent)"
        recordings[index].titleColorHex = hex
        if let hex = hex {
            UserDefaults.standard.set(hex, forKey: colorKey)
        } else {
            UserDefaults.standard.removeObject(forKey: colorKey)
        }
    }
    
    func renameRecording(_ recording: Recording, to newTitle: String) {
        let safeTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !safeTitle.isEmpty else { return }
        
        let directory = recording.fileURL.deletingLastPathComponent()
        let newURL = directory.appendingPathComponent("\(safeTitle).m4a")
        
        guard !FileManager.default.fileExists(atPath: newURL.path) else { return } // Prevent overwrite
        
        do {
            try FileManager.default.moveItem(at: recording.fileURL, to: newURL)
            if playingURL == recording.fileURL {
                playingURL = newURL
            }
            fetchRecordings()
        } catch {
            print("Failed to rename recording: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Import & Sharing Helpers
    func importAudioFile(from sourceURL: URL) {
        let fileManager = FileManager.default
        let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let originalName = sourceURL.deletingPathExtension().lastPathComponent
        let targetFilename = "\(originalName)_\(Int(Date().timeIntervalSince1970)).\(ext)"
        let targetURL = documentPath.appendingPathComponent(targetFilename)
        
        do {
            if fileManager.fileExists(atPath: targetURL.path) {
                try fileManager.removeItem(at: targetURL)
            }
            try fileManager.copyItem(at: sourceURL, to: targetURL)
            
            // Automatically mark imported files as shared since they were imported/shared from outside!
            let shareKey = "isShared_\(targetURL.lastPathComponent)"
            UserDefaults.standard.set(true, forKey: shareKey)
            
            fetchRecordings()
        } catch {
            print("Failed to import audio file: \(error.localizedDescription)")
        }
    }
    
    func markAsShared(recording: Recording) {
        let shareKey = "isShared_\(recording.fileURL.lastPathComponent)"
        UserDefaults.standard.set(true, forKey: shareKey)
        fetchRecordings()
    }
    
    func markRecordingsAsShared(_ recordingsList: [Recording]) {
        for rec in recordingsList {
            let shareKey = "isShared_\(rec.fileURL.lastPathComponent)"
            UserDefaults.standard.set(true, forKey: shareKey)
        }
        fetchRecordings()
    }
}
