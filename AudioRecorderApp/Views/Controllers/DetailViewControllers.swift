import UIKit
import Speech

// MARK: - TranscriptViewController
class TranscriptViewController: UIViewController {
    var recording: Recording!
    private let speechRecognizer = SpeechRecognizer()
    
    private var statusLabel: UILabel!
    private var textView: UITextView!
    private var activityIndicator: UIActivityIndicatorView!
    
    static func instantiate(recording: Recording) -> TranscriptViewController {
        return TranscriptViewController(recording: recording)
    }
    
    init(recording: Recording) {
        self.recording = recording
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .notesBackground
        title = "Transcript"
        
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        doneItem.tintColor = .notesAccent
        navigationItem.rightBarButtonItem = doneItem
        
        setupUI()
        bindViewModel()
        
        speechRecognizer.requestAuthorization { [weak self] authorized in
            guard let self = self else { return }
            if authorized {
                self.speechRecognizer.transcribe(audioURL: self.recording.fileURL)
            } else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Speech recognition permission denied."
                    self.statusLabel.isHidden = false
                }
            }
        }
    }
    
    private func setupUI() {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        statusLabel = label
        
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.tintColor = .notesAccent
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)
        activityIndicator = indicator
        
        let text = UITextView()
        text.font = .systemFont(ofSize: 16)
        text.textColor = .label
        text.backgroundColor = .notesCardBackground
        text.layer.borderColor = UIColor.notesBorder.cgColor
        text.layer.borderWidth = 1
        text.layer.cornerRadius = 16
        text.isEditable = false
        text.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        text.isHidden = true
        text.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(text)
        textView = text
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            activityIndicator.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func bindViewModel() {
        speechRecognizer.onStateChange = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if self.speechRecognizer.isTranscribing {
                    self.statusLabel.text = "Transcribing audio..."
                    self.statusLabel.isHidden = false
                    self.activityIndicator.startAnimating()
                    self.textView.isHidden = true
                } else {
                    self.activityIndicator.stopAnimating()
                }
                
                if !self.speechRecognizer.transcript.isEmpty {
                    self.textView.text = self.speechRecognizer.transcript
                    self.textView.isHidden = false
                    self.statusLabel.isHidden = true
                }
                
                if let error = self.speechRecognizer.errorMessage {
                    self.statusLabel.text = "Error: \(error)"
                    self.statusLabel.textColor = .systemRed
                    self.statusLabel.isHidden = false
                }
            }
        }
    }
    
    @objc private func doneTapped() {
        dismiss(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView?.layer.borderColor = UIColor.notesBorder.cgColor
    }
}

// MARK: - PlaybackViewController
class PlaybackViewController: UIViewController {
    var recording: Recording!
    var viewModel: AudioViewModel!
    
    private var titleLabel: UILabel!
    private var elapsedTimeLabel: UILabel!
    private var remainingTimeLabel: UILabel!
    private var slider: UISlider!
    private var playButton: UIButton!
    private var skipBackButton: UIButton!
    private var skipForwardButton: UIButton!
    private var waveformContainerView: UIView!
    
    // Waveform View
    let waveformView = PlaybackWaveformUIView()
    
    static func instantiate(recording: Recording, viewModel: AudioViewModel) -> PlaybackViewController {
        return PlaybackViewController(recording: recording, viewModel: viewModel)
    }
    
    init(recording: Recording, viewModel: AudioViewModel) {
        self.recording = recording
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .notesBackground
        
        setupUI()
        bindViewModel()
        
        viewModel.playPause(recording: recording)
    }
    
    private func setupUI() {
        let lbl = UILabel()
        lbl.text = recording.title
        lbl.font = .systemFont(ofSize: 24, weight: .bold)
        lbl.textColor = .label
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        titleLabel = lbl
        
        let elapsed = UILabel()
        elapsed.text = "00:00"
        elapsed.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        elapsed.textColor = .secondaryLabel
        elapsedTimeLabel = elapsed
        
        let remaining = UILabel()
        remaining.text = "-00:00"
        remaining.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        remaining.textColor = .secondaryLabel
        remainingTimeLabel = remaining
        
        let sld = UISlider()
        sld.minimumTrackTintColor = .notesAccent
        sld.maximumTrackTintColor = .notesBorder
        sld.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider = sld
        
        let timeLabelsStack = UIStackView(arrangedSubviews: [elapsedTimeLabel, remainingTimeLabel])
        timeLabelsStack.axis = .horizontal
        timeLabelsStack.distribution = .equalSpacing
        
        let sliderContainerStack = UIStackView(arrangedSubviews: [slider, timeLabelsStack])
        sliderContainerStack.axis = .vertical
        sliderContainerStack.spacing = 8
        
        let playBtn = UIButton(type: .system)
        playBtn.tintColor = .notesAccent
        playBtn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 52), forImageIn: .normal)
        playBtn.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        playButton = playBtn
        
        let skipBack = UIButton(type: .system)
        skipBack.tintColor = .notesAccent
        skipBack.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        skipBack.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 28), forImageIn: .normal)
        skipBack.addTarget(self, action: #selector(skipBackwardTapped), for: .touchUpInside)
        skipBackButton = skipBack
        
        let skipFwd = UIButton(type: .system)
        skipFwd.tintColor = .notesAccent
        skipFwd.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        skipFwd.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 28), forImageIn: .normal)
        skipFwd.addTarget(self, action: #selector(skipForwardTapped), for: .touchUpInside)
        skipForwardButton = skipFwd
        
        let controlsStack = UIStackView(arrangedSubviews: [skipBackButton, playButton, skipForwardButton])
        controlsStack.axis = .horizontal
        controlsStack.spacing = 40
        controlsStack.alignment = .center
        controlsStack.distribution = .equalSpacing
        
        let contentStack = UIStackView(arrangedSubviews: [titleLabel, waveformView, sliderContainerStack, controlsStack])
        contentStack.axis = .vertical
        contentStack.spacing = 38
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            waveformView.heightAnchor.constraint(equalToConstant: 80),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28)
        ])
    }
    
    private func bindViewModel() {
        viewModel.addStateChangeObserver(identifier: "PlaybackViewController") { [weak self] in
            guard let self = self else { return }
            
            let icon = self.viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill"
            self.playButton.setImage(UIImage(systemName: icon), for: .normal)
            self.waveformView.isAnimating = self.viewModel.isPlaying
            
            if !self.slider.isTracking {
                self.slider.value = Float(self.viewModel.playbackProgress)
            }
            
            let time = self.viewModel.playbackTime
            let elapsedMin = Int(time) / 60
            let elapsedSec = Int(time) % 60
            self.elapsedTimeLabel.text = String(format: "%02d:%02d", elapsedMin, elapsedSec)
            
            let remaining = max(0, self.recording.duration - time)
            let remainingMin = Int(remaining) / 60
            let remainingSec = Int(remaining) % 60
            self.remainingTimeLabel.text = String(format: "-%02d:%02d", remainingMin, remainingSec)
            
            self.waveformView.audioSamples = [CGFloat(self.viewModel.currentPlaybackLevel)]
        }
    }
    
    @objc private func playTapped() {
        viewModel.playPause(recording: recording)
    }
    
    @objc private func sliderChanged() {
        viewModel.seekPlayback(to: Double(slider.value))
    }
    
    @objc private func skipBackwardTapped() {
        let targetTime = max(0, viewModel.playbackTime - 15)
        let progress = targetTime / recording.duration
        viewModel.seekPlayback(to: progress)
    }
    
    @objc private func skipForwardTapped() {
        let targetTime = min(recording.duration, viewModel.playbackTime + 15)
        let progress = targetTime / recording.duration
        viewModel.seekPlayback(to: progress)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.stopPlayback()
        viewModel.removeStateChangeObserver(identifier: "PlaybackViewController")
    }
}

// MARK: - CalendarFilterViewController
class CalendarFilterViewController: UIViewController {
    var viewModel: AudioViewModel!
    
    private var clearButton: UIButton!
    private var datePicker: UIDatePicker!
    
    static func instantiate(viewModel: AudioViewModel) -> CalendarFilterViewController {
        return CalendarFilterViewController(viewModel: viewModel)
    }
    
    init(viewModel: AudioViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .notesBackground
        title = "Filter by Date"
        
        let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        cancelItem.tintColor = .notesAccent
        navigationItem.leftBarButtonItem = cancelItem
        
        setupUI()
    }
    
    private func setupUI() {
        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("Clear Filter", for: .normal)
        clearBtn.setTitleColor(.systemRed, for: .normal)
        clearBtn.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        clearBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearBtn)
        clearButton = clearBtn
        
        NSLayoutConstraint.activate([
            clearButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clearButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40)
        ])
        
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.tintColor = .notesAccent
        picker.preferredDatePickerStyle = .inline
        if let current = viewModel.selectedDate {
            picker.date = current
        }
        picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        picker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(picker)
        datePicker = picker
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Force UIDatePicker to show full inline calendar grid and prevent clipping at bottom
        datePicker.preferredDatePickerStyle = .inline
        datePicker.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func clearTapped() {
        viewModel.selectedDate = nil
        dismiss(animated: true)
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        viewModel.selectedDate = sender.date
        dismiss(animated: true)
    }
}

// MARK: - SideMenuViewController (Settings & Filters Panel)
class SideMenuViewController: UIViewController {
    var viewModel: AudioViewModel!
    
    var dimmingView: UIView!
    var menuView: UIView!
    var headerLabel: UILabel!
    var themeIcon: UIImageView!
    var themeLabel: UILabel!
    var themeSwitch: UISwitch!
    var separator: UIView!
    
    var versionLabel: UILabel!
    var copyrightLabel: UILabel!
    var rowsStack: UIStackView!
    
    var menuLeadingConstraint: NSLayoutConstraint!
    
    static func instantiate(viewModel: AudioViewModel) -> SideMenuViewController {
        let vc = SideMenuViewController(viewModel: viewModel)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = vc
        return vc
    }
    
    init(viewModel: AudioViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Keep menu off-screen initially so the animator slides it in fresh
        menuLeadingConstraint.constant = -280
        dimmingView.alpha = 0
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        let dimView = UIView()
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        dimmingView = dimView
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        dimmingView.addGestureRecognizer(tap)
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissMenu))
        swipe.direction = .left
        view.addGestureRecognizer(swipe)
        
        let container = UIView()
        container.backgroundColor = .notesCardBackground
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        menuView = container
        
        let header = UILabel()
        header.text = "Settings"
        header.font = .systemFont(ofSize: 24, weight: .bold)
        header.textColor = .label
        header.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(header)
        headerLabel = header
        
        let thmIcon = UIImageView(image: UIImage(systemName: "sun.max.fill"))
        thmIcon.tintColor = .notesAccent
        thmIcon.contentMode = .scaleAspectFit
        thmIcon.translatesAutoresizingMaskIntoConstraints = false
        themeIcon = thmIcon
        
        let thmLabel = UILabel()
        thmLabel.text = "Dark Mode"
        thmLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        thmLabel.textColor = .label
        thmLabel.translatesAutoresizingMaskIntoConstraints = false
        themeLabel = thmLabel
        
        let thmSwitch = UISwitch()
        let isDark = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
        thmSwitch.isOn = isDark
        thmSwitch.onTintColor = .notesAccent
        thmSwitch.addTarget(self, action: #selector(themeChanged(_:)), for: .valueChanged)
        thmSwitch.translatesAutoresizingMaskIntoConstraints = false
        themeSwitch = thmSwitch
        
        let themeStack = UIStackView(arrangedSubviews: [themeIcon, themeLabel, themeSwitch])
        themeStack.axis = .horizontal
        themeStack.spacing = 12
        themeStack.alignment = .center
        themeStack.distribution = .fill
        themeStack.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(themeStack)
        
        let sep = UIView()
        sep.backgroundColor = .notesBorder
        sep.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(sep)
        separator = sep
        
        let allRow = createMenuRow(iconName: "waveform", title: "All Recordings", action: #selector(allTapped))
        let starRow = createMenuRow(iconName: "star.fill", title: "Starred Recordings", action: #selector(starredTapped))
        let shareRow = createMenuRow(iconName: "square.and.arrow.up", title: "Shared Recordings", action: #selector(sharedTapped))
        
        let rStack = UIStackView(arrangedSubviews: [allRow, starRow, shareRow])
        rStack.axis = .vertical
        rStack.spacing = 16
        rStack.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(rStack)
        rowsStack = rStack
        
        let footerStack = UIStackView()
        footerStack.axis = .vertical
        footerStack.spacing = 6
        footerStack.alignment = .center
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(footerStack)
        
        let verLabel = UILabel()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        verLabel.text = "Version \(version)"
        verLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        verLabel.textColor = .secondaryLabel
        verLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel = verLabel
        
        let cprLabel = UILabel()
        cprLabel.text = "© 2026 Alen C James. All rights reserved."
        cprLabel.font = .systemFont(ofSize: 10, weight: .regular)
        cprLabel.textColor = .secondaryLabel
        cprLabel.translatesAutoresizingMaskIntoConstraints = false
        copyrightLabel = cprLabel
        
        footerStack.addArrangedSubview(versionLabel)
        footerStack.addArrangedSubview(copyrightLabel)
        
        menuLeadingConstraint = menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -280)
        
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            menuView.topAnchor.constraint(equalTo: view.topAnchor),
            menuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            menuLeadingConstraint,
            menuView.widthAnchor.constraint(equalToConstant: 280),
            
            headerLabel.topAnchor.constraint(equalTo: menuView.safeAreaLayoutGuide.topAnchor, constant: 28),
            headerLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 20),
            
            themeStack.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 32),
            themeStack.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 20),
            themeStack.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -20),
            themeIcon.widthAnchor.constraint(equalToConstant: 24),
            themeIcon.heightAnchor.constraint(equalToConstant: 24),
            
            separator.topAnchor.constraint(equalTo: themeStack.bottomAnchor, constant: 24),
            separator.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 1),
            
            rowsStack.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 24),
            rowsStack.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 20),
            rowsStack.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -20),
            
            footerStack.bottomAnchor.constraint(equalTo: menuView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            footerStack.centerXAnchor.constraint(equalTo: menuView.centerXAnchor)
        ])
    }
    
    private func createMenuRow(iconName: String, title: String, action: Selector) -> UIView {
        let container = UIButton(type: .system)
        container.tintColor = .label
        container.contentHorizontalAlignment = .leading
        container.addTarget(self, action: action, for: .touchUpInside)
        
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = iconName == "star.fill" ? .notesAccent : .secondaryLabel
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(icon)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 48),
            
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),
            
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    @objc private func themeChanged(_ sender: UISwitch) {
        let isDark = sender.isOn
        UserDefaults.standard.set(isDark, forKey: "isDarkMode")
        
        let activeWindow = self.view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
            
        if let window = activeWindow {
            UIView.transition(with: window, duration: 0.2, options: .transitionCrossDissolve, animations: {
                window.overrideUserInterfaceStyle = isDark ? .dark : .light
            }, completion: nil)
        }
    }
    
    @objc private func starredTapped() {
        viewModel.selectedFilter = .starred
        dismissMenu()
    }
    
    @objc private func sharedTapped() {
        viewModel.selectedFilter = .shared
        dismissMenu()
    }
    
    @objc private func allTapped() {
        viewModel.selectedFilter = .all
        dismissMenu()
    }
    
    @objc func dismissMenu() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - SideMenu Custom Transition Animator
private class SideMenuPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.35 }
    
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let toVC = ctx.viewController(forKey: .to) as? SideMenuViewController else {
            ctx.completeTransition(false); return
        }
        let container = ctx.containerView
        container.addSubview(toVC.view)
        toVC.view.frame = ctx.finalFrame(for: toVC)
        
        // Start: menu off-screen left, dimming invisible
        toVC.menuLeadingConstraint?.constant = -280
        toVC.dimmingView?.alpha = 0
        toVC.view.layoutIfNeeded()
        
        UIView.animate(
            withDuration: transitionDuration(using: ctx),
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                toVC.menuLeadingConstraint?.constant = 0
                toVC.dimmingView?.alpha = 1
                toVC.view.layoutIfNeeded()
            },
            completion: { finished in
                ctx.completeTransition(finished)
            }
        )
    }
}

private class SideMenuDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.28 }
    
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let fromVC = ctx.viewController(forKey: .from) as? SideMenuViewController else {
            ctx.completeTransition(false); return
        }
        
        UIView.animate(
            withDuration: transitionDuration(using: ctx),
            delay: 0,
            options: .curveEaseIn,
            animations: {
                fromVC.menuLeadingConstraint?.constant = -280
                fromVC.dimmingView?.alpha = 0
                fromVC.view.layoutIfNeeded()
            },
            completion: { finished in
                fromVC.view.removeFromSuperview()
                ctx.completeTransition(finished)
            }
        )
    }
}

// MARK: - SideMenuViewController: UIViewControllerTransitioningDelegate
extension SideMenuViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SideMenuPresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SideMenuDismissAnimator()
    }
}
