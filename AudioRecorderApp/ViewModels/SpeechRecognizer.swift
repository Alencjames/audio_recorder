import Foundation
import Speech

class SpeechRecognizer {
    var onStateChange: (() -> Void)?
    
    var transcript = "" {
        didSet { onStateChange?() }
    }
    
    var isTranscribing = false {
        didSet { onStateChange?() }
    }
    
    var errorMessage: String? = nil {
        didSet { onStateChange?() }
    }
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
    
    func transcribe(audioURL: URL) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition is not available."
            return
        }
        
        isTranscribing = true
        transcript = ""
        errorMessage = nil
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = true // Show partial results for better UX
        
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.isTranscribing = false
                    }
                }
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isTranscribing = false
                }
            }
        }
    }
}
