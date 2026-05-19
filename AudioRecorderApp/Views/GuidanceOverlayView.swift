import UIKit

struct TourStep {
    let targetView: UIView?
    let title: String
    let description: String
}

class GuidanceOverlayView: UIView {
    private var steps: [TourStep] = []
    private var currentStepIndex = 0
    
    // UI Elements
    private let cardContainer = UIView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let nextButton = UIButton()
    private let skipButton = UIButton()
    private let progressLabel = UILabel()
    
    private let backgroundMaskLayer = CAShapeLayer()
    private var spotlightPadding: CGFloat = 8
    
    private var cardTopConstraint: NSLayoutConstraint?
    private var cardBottomConstraint: NSLayoutConstraint?
    private var cardCenterXConstraint: NSLayoutConstraint?
    
    var onCompletion: (() -> Void)?
    
    init(frame: CGRect, steps: [TourStep]) {
        super.init(frame: frame)
        self.steps = steps
        setupOverlay()
        setupCard()
        showStep(index: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupOverlay() {
        backgroundColor = .clear
        
        backgroundMaskLayer.fillColor = UIColor.black.withAlphaComponent(0.75).cgColor
        backgroundMaskLayer.fillRule = .evenOdd
        layer.addSublayer(backgroundMaskLayer)
    }
    
    private func setupCard() {
        // Blur background for card to look extremely premium
        cardContainer.backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 25/255, green: 25/255, blue: 27/255, alpha: 0.95)
                : UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.98)
        }
        cardContainer.layer.cornerRadius = 20
        cardContainer.layer.borderColor = UIColor.notesAccent.cgColor
        cardContainer.layer.borderWidth = 1.5
        
        // Add drop shadow
        cardContainer.layer.shadowColor = UIColor.black.cgColor
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        cardContainer.layer.shadowRadius = 12
        cardContainer.layer.shadowOpacity = 0.35
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardContainer)
        
        // Title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .notesAccent
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(titleLabel)
        
        // Description
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = .label
        descLabel.numberOfLines = 0
        descLabel.lineBreakMode = .byWordWrapping
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(descLabel)
        
        // Progress indicator
        progressLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        progressLabel.textColor = .secondaryLabel
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(progressLabel)
        
        // Next Button
        var nextConfig = UIButton.Configuration.filled()
        nextConfig.baseBackgroundColor = .notesAccent
        nextConfig.baseForegroundColor = .black
        nextConfig.cornerStyle = .capsule
        nextConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18)
        
        nextButton.configuration = nextConfig
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(nextButton)
        
        // Skip Button
        skipButton.setTitle("Skip Tour", for: .normal)
        skipButton.setTitleColor(.secondaryLabel, for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(skipButton)
        
        // Setup base constraints inside card
        NSLayoutConstraint.activate([
            cardContainer.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.85),
            
            titleLabel.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -18),
            
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 18),
            descLabel.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -18),
            
            progressLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            progressLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 18),
            progressLabel.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
            
            nextButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 14),
            nextButton.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -18),
            nextButton.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -18),
            
            skipButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
            skipButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -12)
        ])
        
        // Setup floating constraints for card container positioning
        cardCenterXConstraint = cardContainer.centerXAnchor.constraint(equalTo: centerXAnchor)
        cardCenterXConstraint?.isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundMaskLayer.frame = bounds
        updateSpotlight()
    }
    
    private func showStep(index: Int) {
        guard index < steps.count else { return }
        currentStepIndex = index
        
        let step = steps[index]
        titleLabel.text = step.title
        descLabel.text = step.description
        progressLabel.text = "\(index + 1) of \(steps.count)"
        
        if index == steps.count - 1 {
            nextButton.setTitle("Get Started", for: .normal)
            skipButton.isHidden = true
        } else {
            nextButton.setTitle("Next", for: .normal)
            skipButton.isHidden = false
        }
        
        // Animate transition elegantly
        cardContainer.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        cardContainer.alpha = 0.5
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.cardContainer.transform = .identity
            self.cardContainer.alpha = 1.0
            self.updateSpotlight()
        }, completion: nil)
    }
    
    private func updateSpotlight() {
        guard currentStepIndex < steps.count else { return }
        let step = steps[currentStepIndex]
        
        let maskPath = UIBezierPath(rect: bounds)
        
        if let target = step.targetView {
            // Convert coordinate system relative to this overlay
            let targetRect = target.convert(target.bounds, to: self)
            
            // Generate circular or rounded rect spotlight cutout
            let spotlightRadius = max(targetRect.width, targetRect.height) / 2 + spotlightPadding
            let spotlightCenter = CGPoint(x: targetRect.midX, y: targetRect.midY)
            let spotlightPath = UIBezierPath(arcCenter: spotlightCenter, radius: spotlightRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            
            maskPath.append(spotlightPath)
            
            // Intelligently position card container above or below target rect to avoid overlap
            cardTopConstraint?.isActive = false
            cardBottomConstraint?.isActive = false
            
            if targetRect.midY > bounds.height / 2 {
                // Target is in bottom half -> Position card above target
                cardBottomConstraint = cardContainer.bottomAnchor.constraint(equalTo: topAnchor, constant: targetRect.minY - 20)
                cardBottomConstraint?.isActive = true
            } else {
                // Target is in top half -> Position card below target
                cardTopConstraint = cardContainer.topAnchor.constraint(equalTo: topAnchor, constant: targetRect.maxY + 20)
                cardTopConstraint?.isActive = true
            }
        } else {
            // No target -> center card container on screen
            cardTopConstraint?.isActive = false
            cardBottomConstraint?.isActive = false
            
            cardTopConstraint = cardContainer.centerYAnchor.constraint(equalTo: centerYAnchor)
            cardTopConstraint?.isActive = true
        }
        
        backgroundMaskLayer.path = maskPath.cgPath
    }
    
    @objc private func nextTapped() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if currentStepIndex + 1 < steps.count {
            showStep(index: currentStepIndex + 1)
        } else {
            completeTour()
        }
    }
    
    @objc private func skipTapped() {
        completeTour()
    }
    
    private func completeTour() {
        UIView.animate(withDuration: 0.35, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            self.onCompletion?()
        }
    }
}
