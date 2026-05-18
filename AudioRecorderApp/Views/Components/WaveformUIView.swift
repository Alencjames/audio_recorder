import UIKit

// MARK: - WaveformUIView (Main Recording Screen)
class WaveformUIView: UIView {
    private var displayLink: CADisplayLink?
    private let waveLayer1 = CAShapeLayer()
    private let waveLayer2 = CAShapeLayer()
    private var phase: CGFloat = 0.0
    
    var audioSamples: [CGFloat] = [] {
        didSet {
            currentAmplitude = max(0.1, min((audioSamples.last ?? 0.2) * 2.0, 1.0))
        }
    }
    
    private var currentAmplitude: CGFloat = 0.2
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        startAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        startAnimation()
    }
    
    private func setupLayers() {
        waveLayer2.fillColor = UIColor.notesAccent.withAlphaComponent(0.3).cgColor
        layer.addSublayer(waveLayer2)
        
        waveLayer1.fillColor = UIColor.notesAccent.withAlphaComponent(0.5).cgColor
        layer.addSublayer(waveLayer1)
    }
    
    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateWave))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateWave() {
        phase += 0.05
        let width = bounds.width
        let height = bounds.height
        
        guard width > 0 && height > 0 else { return }
        
        let midHeight = height * 0.7
        let waveHeight = height * 0.25 * currentAmplitude
        
        // Front Wave
        let path1 = UIBezierPath()
        path1.move(to: CGPoint(x: 0, y: height))
        path1.addLine(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin((relativeX * .pi * 2.5) + phase)
            let y = midHeight + (sine * waveHeight)
            path1.addLine(to: CGPoint(x: x, y: y))
        }
        path1.addLine(to: CGPoint(x: width, y: height))
        path1.close()
        waveLayer1.path = path1.cgPath
        
        // Back Wave
        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: 0, y: height))
        path2.addLine(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin((relativeX * .pi * 2.0) + phase * 1.5)
            let y = midHeight + (sine * waveHeight * 0.8)
            path2.addLine(to: CGPoint(x: x, y: y))
        }
        path2.addLine(to: CGPoint(x: width, y: height))
        path2.close()
        waveLayer2.path = path2.cgPath
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        waveLayer1.frame = bounds
        waveLayer2.frame = bounds
    }
    
    deinit {
        displayLink?.invalidate()
    }
}

// MARK: - PlaybackWaveformUIView (Playback Detail Sheet Screen)
class PlaybackWaveformUIView: UIView {
    private var displayLink: CADisplayLink?
    private let waveLayer = CAShapeLayer()
    private var phase: CGFloat = 0.0
    
    // Wave customizable parameters
    private let barWidth: CGFloat = 3.0
    private let barSpacing: CGFloat = 3.0
    private var barFactors: [CGFloat] = []
    
    var audioSamples: [CGFloat] = [] {
        didSet {
            // Snappy amplitude tracking with no artificial minimum limit
            let targetAmp = max(0.0, min(audioSamples.last ?? 0.0, 1.0))
            currentAmplitude = currentAmplitude * 0.4 + targetAmp * 0.6
        }
    }
    
    private var currentAmplitude: CGFloat = 0.0
    
    var isAnimating: Bool = true {
        didSet {
            displayLink?.isPaused = !isAnimating
            if !isAnimating {
                // Instantly flatten to calm static state
                currentAmplitude = 0.0
                updateWave()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFactors()
        setupLayers()
        startAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFactors()
        setupLayers()
        startAnimation()
    }
    
    private func setupFactors() {
        // Pre-generate 60 bar scale factors forming a beautiful multi-peak soundwave silhouette
        barFactors = (0..<60).map { i -> CGFloat in
            let progress = CGFloat(i) / 60.0
            // Silhouette envelope: drops at edges, peaks in clusters
            let envelope = sin(progress * .pi) // Curved bell drop-off at edges
            let multiPeak = abs(sin(progress * .pi * 3.5)) // 3 clusters of peaks
            return max(0.08, envelope * multiPeak)
        }
    }
    
    private func setupLayers() {
        waveLayer.fillColor = UIColor.clear.cgColor
        waveLayer.strokeColor = UIColor.notesAccent.cgColor
        waveLayer.lineWidth = barWidth
        waveLayer.lineCap = .round
        layer.addSublayer(waveLayer)
    }
    
    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateWave))
        displayLink?.isPaused = !isAnimating
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateWave() {
        phase += 0.05
        let width = bounds.width
        let height = bounds.height
        
        guard width > 0 && height > 0 else { return }
        
        let path = UIBezierPath()
        let barCount = barFactors.count
        let totalWidth = CGFloat(barCount) * (barWidth + barSpacing) - barSpacing
        let startX = (width - totalWidth) / 2.0
        let centerY = height / 2.0
        
        for i in 0..<barCount {
            let baseFactor = barFactors[i]
            // Add a beautiful dynamic organic micro-wobble to each bar using its index and phase
            let wobble = 1.0 + 0.25 * sin(phase * 4.0 + CGFloat(i) * 0.35)
            
            let maxPossibleHalfHeight = (height - 8.0) / 2.0
            let halfHeight = maxPossibleHalfHeight * baseFactor * currentAmplitude * wobble
            
            // Minimum half-height of 1.5 so we see a neat tiny rounded dot even when quiet
            let clampHalfHeight = max(1.5, halfHeight)
            
            let x = startX + CGFloat(i) * (barWidth + barSpacing) + (barWidth / 2.0)
            
            path.move(to: CGPoint(x: x, y: centerY - clampHalfHeight))
            path.addLine(to: CGPoint(x: x, y: centerY + clampHalfHeight))
        }
        
        waveLayer.path = path.cgPath
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        waveLayer.frame = bounds
    }
    
    deinit {
        displayLink?.invalidate()
    }
}
