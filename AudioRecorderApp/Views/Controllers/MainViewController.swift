import UIKit
import UniformTypeIdentifiers

class MainViewController: UIViewController {
    private let viewModel = AudioViewModel()
    
    // UI Elements
    private let headerLabel = UILabel()
    private let searchContainer = UIView()
    private let searchTextField = UITextField()
    private var filtersCollectionView: UICollectionView!
    private let tableView = UITableView()
    
    private var plusButton: UIButton!
    private var calendarButton: UIButton!
    private var settingsButton: UIButton!
    private var askAIButton: UIButton!
    private var searchIcon: UIImageView!
    
    // Record Area
    private let recordButton = UIButton()
    private let recordButtonInner = UIView()
    private let waveformContainer = UIView()
    private let waveformView = WaveformUIView()
    private var pauseButton: UIButton!
    private var micIcon: UIImageView!
    
    // Selection Toolbar
    private let bottomToolbar = UIView()
    private var toolbarTitleLabel = UILabel()
    private var toolbarStarButton = UIButton()
    private var toolbarShareButton = UIButton()
    private var toolbarDeleteButton = UIButton()
    private var toolbarCancelButton = UIButton()
    private var bottomToolbarConstraint: NSLayoutConstraint!
    
    // Constraints
    private var waveformHeightConstraint: NSLayoutConstraint!
    
    // Tracks which recording is being colour-picked
    private var recordingBeingColored: Recording?
    
    // Multiple Selection Mode properties
    private var isSelectionMode = false
    private var selectedRecordings = Set<UUID>()
    private var lastIsRecording: Bool?
    
    private var recordButtonBorderColor: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 60/255, green: 60/255, blue: 65/255, alpha: 1.0)
                : UIColor(red: 210/255, green: 210/255, blue: 215/255, alpha: 1.0)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showFirstTimeGuidanceIfNeeded()
    }
    
    private func showFirstTimeGuidanceIfNeeded() {
        let hasSeen = UserDefaults.standard.bool(forKey: "hasSeenFirstTimeGuidance")
        if !hasSeen {
            let steps = [
                TourStep(
                    targetView: recordButton,
                    title: "🎙️ Start Recording",
                    description: "Tap the main microphone button to start recording your voice memo with live, frame-accurate waveforms."
                ),
                TourStep(
                    targetView: searchContainer,
                    title: "🔍 Smart Search & AI",
                    description: "Quickly search through your audio titles or tap 'Ask AI' to generate summaries and smart transcripts."
                ),
                TourStep(
                    targetView: plusButton,
                    title: "➕ Import Audio",
                    description: "Tap the plus button to easily import external audio files from your device and add them directly to your recordings list."
                ),
                TourStep(
                    targetView: calendarButton,
                    title: "📅 Calendar Filters",
                    description: "Tap the calendar button to filter voice recordings by selecting specific calendar dates."
                ),
                TourStep(
                    targetView: settingsButton,
                    title: "⚙️ Preferences & Theme",
                    description: "Tap the gear settings icon to switch colors, styles, and toggle dynamic light and dark theme mode."
                )
            ]
            
            let guidanceView = GuidanceOverlayView(frame: view.bounds, steps: steps)
            guidanceView.onCompletion = {
                UserDefaults.standard.set(true, forKey: "hasSeenFirstTimeGuidance")
            }
            view.addSubview(guidanceView)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .notesBackground
        
        setupHeader()
        setupSearchBar()
        setupFilters()
        setupTableView()
        setupRecordArea()
        
        setupBottomToolbar()
        bindViewModel()
        
        viewModel.requestMicrophonePermission()
    }
    
    // MARK: - Setup UI
    private func setupHeader() {
        headerLabel.text = "Recordings"
        headerLabel.font = .systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = .label
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)
        
        let actionsStack = UIStackView()
        actionsStack.axis = .horizontal
        actionsStack.spacing = 16
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionsStack)
        
        let plusBtn = createIconButton(systemName: "plus", action: #selector(plusTapped))
        let calBtn = createIconButton(systemName: "calendar", action: #selector(openCalendar))
        let gearBtn = createIconButton(systemName: "gearshape", action: #selector(settingsTapped))
        
        actionsStack.addArrangedSubview(plusBtn)
        actionsStack.addArrangedSubview(calBtn)
        actionsStack.addArrangedSubview(gearBtn)
        
        plusButton = plusBtn
        calendarButton = calBtn
        settingsButton = gearBtn
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            actionsStack.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupSearchBar() {
        searchContainer.backgroundColor = .notesCardBackground
        searchContainer.layer.cornerRadius = 20
        searchContainer.layer.borderColor = UIColor.notesBorder.cgColor
        searchContainer.layer.borderWidth = 1
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchContainer)
        
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .notesAccent
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        searchTextField.placeholder = "Search"
        searchTextField.textColor = .label
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        
        var aiConfig = UIButton.Configuration.filled()
        aiConfig.title = "Ask AI"
        aiConfig.image = UIImage(systemName: "sparkles")
        aiConfig.imagePadding = 4
        aiConfig.imagePlacement = .leading
        aiConfig.baseForegroundColor = .black
        aiConfig.baseBackgroundColor = .notesAccent
        aiConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        aiConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }
        let aiButton = UIButton(configuration: aiConfig)
        aiButton.layer.cornerRadius = 16
        aiButton.clipsToBounds = true
        aiButton.layer.shadowColor = UIColor.black.cgColor
        aiButton.layer.shadowOpacity = 0.05
        aiButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        aiButton.layer.shadowRadius = 2
        aiButton.addTarget(self, action: #selector(showFeatureAlert), for: .touchUpInside)
        aiButton.translatesAutoresizingMaskIntoConstraints = false
        
        searchContainer.addSubview(icon)
        searchContainer.addSubview(searchTextField)
        searchContainer.addSubview(aiButton)
        
        askAIButton = aiButton
        searchIcon = icon
        
        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainer.heightAnchor.constraint(equalToConstant: 44),
            
            icon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
            
            searchTextField.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchTextField.trailingAnchor.constraint(equalTo: aiButton.leadingAnchor, constant: -8),
            searchTextField.topAnchor.constraint(equalTo: searchContainer.topAnchor),
            searchTextField.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor),
            
            aiButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -6),
            aiButton.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            aiButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupFilters() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(width: 80, height: 32)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        filtersCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        filtersCollectionView.backgroundColor = .clear
        filtersCollectionView.showsHorizontalScrollIndicator = false
        filtersCollectionView.delegate = self
        filtersCollectionView.dataSource = self
        filtersCollectionView.register(FilterCell.self, forCellWithReuseIdentifier: "FilterCell")
        filtersCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filtersCollectionView)
        
        NSLayoutConstraint.activate([
            filtersCollectionView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 16),
            filtersCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filtersCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filtersCollectionView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(RecordingTableViewCell.self, forCellReuseIdentifier: RecordingTableViewCell.identifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
        
        // Add bottom padding so list doesn't hide behind record button
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 150, right: 0)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filtersCollectionView.bottomAnchor, constant: 9),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupRecordArea() {
        recordButton.layer.cornerRadius = 40
        recordButton.layer.borderWidth = 4
        recordButton.layer.borderColor = recordButtonBorderColor.cgColor
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordButton)
        
        recordButtonInner.layer.cornerRadius = 32
        recordButtonInner.backgroundColor = .notesAccent
        recordButtonInner.isUserInteractionEnabled = false
        recordButtonInner.translatesAutoresizingMaskIntoConstraints = false
        recordButton.addSubview(recordButtonInner)
        
        micIcon = UIImageView(image: UIImage(systemName: "mic.fill"))
        micIcon.tintColor = .black
        micIcon.contentMode = .scaleAspectFit
        micIcon.translatesAutoresizingMaskIntoConstraints = false
        recordButtonInner.addSubview(micIcon)
        NSLayoutConstraint.activate([
            micIcon.centerXAnchor.constraint(equalTo: recordButtonInner.centerXAnchor),
            micIcon.centerYAnchor.constraint(equalTo: recordButtonInner.centerYAnchor),
            micIcon.widthAnchor.constraint(equalToConstant: 24),
            micIcon.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        waveformContainer.backgroundColor = .notesCardBackground
        waveformContainer.layer.cornerRadius = 35
        waveformContainer.layer.borderColor = UIColor.notesBorder.cgColor
        waveformContainer.layer.borderWidth = 1
        waveformContainer.clipsToBounds = true
        waveformContainer.alpha = 0
        waveformContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(waveformContainer)
        
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        waveformContainer.addSubview(waveformView)
        
        let pauseBtn = UIButton(type: .system)
        pauseBtn.tintColor = .notesAccent
        pauseBtn.titleLabel?.font = .monospacedSystemFont(ofSize: 18, weight: .semibold)
        pauseBtn.addTarget(self, action: #selector(pauseResumeTapped), for: .touchUpInside)
        pauseBtn.translatesAutoresizingMaskIntoConstraints = false
        waveformContainer.addSubview(pauseBtn)
        pauseButton = pauseBtn
        
        waveformHeightConstraint = waveformContainer.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80),
            
            recordButtonInner.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor),
            recordButtonInner.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            recordButtonInner.widthAnchor.constraint(equalToConstant: 64),
            recordButtonInner.heightAnchor.constraint(equalToConstant: 64),
            
            waveformContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            waveformContainer.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -16),
            waveformContainer.widthAnchor.constraint(equalToConstant: 250),
            waveformHeightConstraint,
            
            waveformView.leadingAnchor.constraint(equalTo: waveformContainer.leadingAnchor),
            waveformView.trailingAnchor.constraint(equalTo: waveformContainer.trailingAnchor),
            waveformView.bottomAnchor.constraint(equalTo: waveformContainer.bottomAnchor),
            waveformView.heightAnchor.constraint(equalToConstant: 40),
            
            pauseButton.centerXAnchor.constraint(equalTo: waveformContainer.centerXAnchor),
            pauseButton.bottomAnchor.constraint(equalTo: waveformContainer.bottomAnchor, constant: -20)
        ])
    }
    
    private func createIconButton(systemName: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: systemName), for: .normal)
        btn.tintColor = .notesAccent
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.widthAnchor.constraint(equalToConstant: 24).isActive = true
        return btn
    }
    
    
    
    // MARK: - UIKit State Bindings
    private func bindViewModel() {
        viewModel.addStateChangeObserver(identifier: "MainViewController") { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.filtersCollectionView.reloadData()
            
            if self.lastIsRecording != self.viewModel.isRecording {
                self.lastIsRecording = self.viewModel.isRecording
                self.updateRecordingUI(isRecording: self.viewModel.isRecording)
            }
            
            self.waveformView.alpha = self.viewModel.isRecordingPaused ? 0.3 : 1.0
        }
        
        viewModel.onRecordingTimeChanged = { [weak self] _ in
            guard let self = self else { return }
            self.updatePauseButton()
        }
        
        viewModel.onAudioSamplesChanged = { [weak self] samples in
            guard let self = self else { return }
            self.waveformView.audioSamples = samples
        }
    }
    
    // MARK: - Actions
    @objc private func toggleRecording() {
        viewModel.toggleRecording()
    }
    
    @objc private func pauseResumeTapped() {
        viewModel.pauseResumeRecording()
    }
    
    @objc private func searchTextChanged() {
        viewModel.searchQuery = searchTextField.text ?? ""
    }
    
    @objc private func showFeatureAlert() {
        let alert = UIAlertController(title: "Feature Not Available", message: "This feature will be available in a future update.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func openCalendar() {
        let vc = CalendarFilterViewController.instantiate(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
    
    private func updateRecordingUI(isRecording: Bool) {
        // Flush all pending layout changes immediately without animation first
        self.view.layoutIfNeeded()
        
        // Animate waveform container height and opacity separately to avoid affecting other UI elements.
        // Update constraint constant first.
        self.waveformHeightConstraint.constant = isRecording ? 70 : 0
        self.waveformContainer.alpha = isRecording ? 1 : 0
        // Animate constraint changes.
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        // Animate record button inner transformations.
        UIView.animate(withDuration: 0.3) {
            if isRecording {
                self.recordButton.layer.borderColor = UIColor.notesAccent.cgColor
                self.recordButtonInner.layer.cornerRadius = 6
                self.recordButtonInner.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self.micIcon.isHidden = true // hide mic icon
            } else {
                self.recordButton.layer.borderColor = self.recordButtonBorderColor.cgColor
                self.recordButtonInner.layer.cornerRadius = 32
                self.recordButtonInner.transform = .identity
                self.micIcon.isHidden = false
            }
        }
    }
    
    private func updatePauseButton() {
        let icon = viewModel.isRecordingPaused ? "play.fill" : "pause.fill"
        let minutes = Int(viewModel.recordingTime) / 60
        let seconds = Int(viewModel.recordingTime) % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        
        pauseButton.setImage(UIImage(systemName: icon), for: .normal)
        pauseButton.setTitle("  \(timeString)", for: .normal)
    }
}

// MARK: - TableView
extension MainViewController: UITableViewDelegate, UITableViewDataSource, RecordingTableViewCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredRecordings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecordingTableViewCell.identifier, for: indexPath) as? RecordingTableViewCell else {
            return UITableViewCell()
        }
        
        let recording = viewModel.filteredRecordings[indexPath.row]
        let isPlaying = viewModel.isPlaying && viewModel.playingURL == recording.fileURL
        let isSelected = selectedRecordings.contains(recording.id)
        
        cell.configure(with: recording, isPlaying: isPlaying, isSelectionMode: isSelectionMode, isSelected: isSelected)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recording = viewModel.filteredRecordings[indexPath.row]
        if isSelectionMode {
            if selectedRecordings.contains(recording.id) {
                selectedRecordings.remove(recording.id)
            } else {
                selectedRecordings.insert(recording.id)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
            updateBottomToolbarCount()
        } else {
            let playbackVC = PlaybackViewController.instantiate(recording: recording, viewModel: viewModel)
            if let sheet = playbackVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
            present(playbackVC, animated: true)
        }
    }
    
    // Cell Delegate
    func didTapPlay(for cell: RecordingTableViewCell) {
        guard let ip = tableView.indexPath(for: cell) else { return }
        viewModel.playPause(recording: viewModel.filteredRecordings[ip.row])
    }
    
    func didTapStar(for cell: RecordingTableViewCell) {
        guard let ip = tableView.indexPath(for: cell) else { return }
        viewModel.toggleStar(for: viewModel.filteredRecordings[ip.row])
    }
    
    func didTapTranscript(for cell: RecordingTableViewCell) {
        guard let ip = tableView.indexPath(for: cell) else { return }
        let recording = viewModel.filteredRecordings[ip.row]
        let transcriptVC = TranscriptViewController.instantiate(recording: recording)
        let nav = UINavigationController(rootViewController: transcriptVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(nav, animated: true)
    }
    
    func didTapColor(for cell: RecordingTableViewCell) {
        guard let ip = tableView.indexPath(for: cell) else { return }
        let recording = viewModel.filteredRecordings[ip.row]
        recordingBeingColored = recording
        
        // Offer colour picker + reset option
        let sheet = UIAlertController(title: "Title Colour", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Choose Colour", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let picker = UIColorPickerViewController()
            picker.selectedColor = recording.titleColor
            picker.supportsAlpha = false
            picker.delegate = self
            self.present(picker, animated: true)
        })
        sheet.addAction(UIAlertAction(title: "Reset to Default", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.setTitleColor(hex: nil, for: recording)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    
    func didTapShare(for cell: RecordingTableViewCell) {
        guard let ip = tableView.indexPath(for: cell) else { return }
        let recording = viewModel.filteredRecordings[ip.row]
        viewModel.markAsShared(recording: recording)
        let shareSheet = UIActivityViewController(activityItems: [recording.fileURL], applicationActivities: nil)
        present(shareSheet, animated: true)
    }
    
    func didTapOptions(for cell: RecordingTableViewCell) {
        guard let ip = tableView.indexPath(for: cell) else { return }
        let recording = viewModel.filteredRecordings[ip.row]
        
        let alert = UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Rename", style: .default, handler: { _ in
            let renameAlert = UIAlertController(title: "Rename Recording", message: nil, preferredStyle: .alert)
            renameAlert.addTextField { tf in
                tf.text = recording.title
            }
            renameAlert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                if let text = renameAlert.textFields?.first?.text {
                    self.viewModel.renameRecording(recording, to: text)
                }
            }))
            renameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(renameAlert, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.viewModel.deleteRecording(recording)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - CollectionView (Filters)
extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return FilterCategory.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCell
        let category = FilterCategory.allCases[indexPath.row]
        cell.configure(title: category.rawValue, isSelected: viewModel.selectedFilter == category)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectedFilter = FilterCategory.allCases[indexPath.row]
    }
}

// Custom Filter Cell
class FilterCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.notesBorder.cgColor
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            contentView.backgroundColor = .notesAccent
            titleLabel.textColor = .black
            contentView.layer.borderColor = UIColor.clear.cgColor
        } else {
            contentView.backgroundColor = .notesCardBackground
            titleLabel.textColor = .label
            contentView.layer.borderColor = UIColor.notesBorder.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if contentView.backgroundColor != .notesAccent {
            contentView.layer.borderColor = UIColor.notesBorder.cgColor
        }
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension MainViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController,
                                   didSelect color: UIColor, continuously: Bool) {
        guard let recording = recordingBeingColored else { return }
        viewModel.setTitleColor(hex: color.hexString, for: recording)
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        recordingBeingColored = nil
    }
}

// MARK: - Multiple Selection Mode & Toolbar Actions
extension MainViewController {
    private func setupBottomToolbar() {
        bottomToolbar.backgroundColor = .notesCardBackground
        bottomToolbar.layer.cornerRadius = 24
        bottomToolbar.layer.borderColor = UIColor.notesBorder.cgColor
        bottomToolbar.layer.borderWidth = 1
        bottomToolbar.layer.shadowColor = UIColor.black.cgColor
        bottomToolbar.layer.shadowOpacity = 0.4
        bottomToolbar.layer.shadowOffset = CGSize(width: 0, height: 4)
        bottomToolbar.layer.shadowRadius = 8
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomToolbar)
        
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        cancelBtn.tintColor = .notesAccent
        cancelBtn.addTarget(self, action: #selector(exitSelectionMode), for: .touchUpInside)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        toolbarCancelButton = cancelBtn
        
        toolbarTitleLabel.text = "0 Selected"
        toolbarTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        toolbarTitleLabel.textColor = .secondaryLabel
        toolbarTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        toolbarStarButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        toolbarStarButton.tintColor = .systemYellow
        toolbarStarButton.addTarget(self, action: #selector(bulkStar), for: .touchUpInside)
        toolbarStarButton.translatesAutoresizingMaskIntoConstraints = false
        
        toolbarShareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        toolbarShareButton.tintColor = .notesAccent
        toolbarShareButton.addTarget(self, action: #selector(bulkShare), for: .touchUpInside)
        toolbarShareButton.translatesAutoresizingMaskIntoConstraints = false
        
        toolbarDeleteButton.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        toolbarDeleteButton.tintColor = .systemRed
        toolbarDeleteButton.addTarget(self, action: #selector(bulkDelete), for: .touchUpInside)
        toolbarDeleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonsStack = UIStackView(arrangedSubviews: [cancelBtn, toolbarTitleLabel, toolbarStarButton, toolbarShareButton, toolbarDeleteButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 16
        buttonsStack.alignment = .center
        buttonsStack.distribution = .equalSpacing
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.addSubview(buttonsStack)
        
        bottomToolbarConstraint = bottomToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 150) // Off-screen
        
        NSLayoutConstraint.activate([
            bottomToolbar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomToolbar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            bottomToolbar.heightAnchor.constraint(equalToConstant: 64),
            bottomToolbarConstraint,
            
            buttonsStack.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            buttonsStack.leadingAnchor.constraint(equalTo: bottomToolbar.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let recording = viewModel.filteredRecordings[indexPath.row]
            enterSelectionMode(startingWith: recording)
        }
    }
    
    private func enterSelectionMode(startingWith recording: Recording) {
        guard !isSelectionMode else { return }
        isSelectionMode = true
        selectedRecordings.removeAll()
        selectedRecordings.insert(recording.id)
        
        updateBottomToolbarCount()
        
        // Slide up bottom toolbar and hide record button
        bottomToolbarConstraint.constant = -30
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: []) {
            self.bottomToolbar.alpha = 1.0
            self.recordButton.alpha = 0.0
            self.recordButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.view.layoutIfNeeded()
        }
        
        tableView.reloadData()
    }
    
    @objc private func exitSelectionMode() {
        guard isSelectionMode else { return }
        isSelectionMode = false
        selectedRecordings.removeAll()
        
        // Slide down bottom toolbar and restore record button
        bottomToolbarConstraint.constant = 150
        UIView.animate(withDuration: 0.3) {
            self.bottomToolbar.alpha = 0.0
            self.recordButton.alpha = 1.0
            self.recordButton.transform = .identity
            self.view.layoutIfNeeded()
        }
        
        tableView.reloadData()
    }
    
    private func updateBottomToolbarCount() {
        toolbarTitleLabel.text = "\(selectedRecordings.count) Selected"
        let hasSelection = !selectedRecordings.isEmpty
        toolbarStarButton.isEnabled = hasSelection
        toolbarShareButton.isEnabled = hasSelection
        toolbarDeleteButton.isEnabled = hasSelection
    }
    
    @objc private func bulkStar() {
        let selected = viewModel.filteredRecordings.filter { selectedRecordings.contains($0.id) }
        guard !selected.isEmpty else { return }
        
        let allStarred = selected.allSatisfy { $0.isStarred }
        selected.forEach { recording in
            if allStarred {
                if recording.isStarred { viewModel.toggleStar(for: recording) }
            } else {
                if !recording.isStarred { viewModel.toggleStar(for: recording) }
            }
        }
        exitSelectionMode()
    }
    
    @objc private func bulkDelete() {
        let selected = viewModel.filteredRecordings.filter { selectedRecordings.contains($0.id) }
        guard !selected.isEmpty else { return }
        
        let alert = UIAlertController(
            title: "Delete Recordings",
            message: "Are you sure you want to delete \(selected.count) recordings?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            selected.forEach { self?.viewModel.deleteRecording($0) }
            self?.exitSelectionMode()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    
    @objc private func bulkShare() {
        let selected = viewModel.filteredRecordings.filter { selectedRecordings.contains($0.id) }
        guard !selected.isEmpty else { return }
        
        viewModel.markRecordingsAsShared(selected)
        let urls = selected.map { $0.fileURL }
        let shareSheet = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        
        if let popover = shareSheet.popoverPresentationController {
            popover.sourceView = bottomToolbar
            popover.sourceRect = toolbarShareButton.frame
        }
        
        present(shareSheet, animated: true)
    }
    
    @objc private func plusTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    @objc private func settingsTapped() {
        let sideMenuVC = SideMenuViewController.instantiate(viewModel: viewModel)
        sideMenuVC.modalPresentationStyle = .overFullScreen
        sideMenuVC.transitioningDelegate = sideMenuVC
        present(sideMenuVC, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchContainer.layer.borderColor = UIColor.notesBorder.cgColor
        waveformContainer.layer.borderColor = UIColor.notesBorder.cgColor
        bottomToolbar.layer.borderColor = UIColor.notesBorder.cgColor
        recordButton.layer.borderColor = recordButtonBorderColor.cgColor
    }
}

// MARK: - UIDocumentPickerDelegate
extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        
        // Start accessing the security-scoped external resource
        guard selectedURL.startAccessingSecurityScopedResource() else {
            // Fallback copy if already accessible
            viewModel.importAudioFile(from: selectedURL)
            return
        }
        
        defer { selectedURL.stopAccessingSecurityScopedResource() }
        viewModel.importAudioFile(from: selectedURL)
    }
}

// MARK: - UITextFieldDelegate & Tap Dismissals
extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
