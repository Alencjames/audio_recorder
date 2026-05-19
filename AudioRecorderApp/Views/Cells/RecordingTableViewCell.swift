import UIKit

protocol RecordingTableViewCellDelegate: AnyObject {
    func didTapPlay(for cell: RecordingTableViewCell)
    func didTapStar(for cell: RecordingTableViewCell)
    func didTapTranscript(for cell: RecordingTableViewCell)
    func didTapOptions(for cell: RecordingTableViewCell)
    func didTapShare(for cell: RecordingTableViewCell)
    func didTapColor(for cell: RecordingTableViewCell)
}

class RecordingTableViewCell: UITableViewCell {
    static let identifier = "RecordingTableViewCell"
    
    weak var delegate: RecordingTableViewCellDelegate?
    
    private let containerView = UIView()
    private let selectImageView = UIImageView()
    private let contentWrapper = UIView()
    
    private let dateLabel = UILabel()
    private let titleLabel = UILabel()
    private var playButton = UIButton(type: .system)
    
    private let starButton = UIButton(type: .system)
    private let transcriptButton = UIButton(type: .system)
    private let editButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let optionsButton = UIButton(type: .system)
    
    private var selectWidthConstraint: NSLayoutConstraint!
    private var selectTrailingConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        containerView.backgroundColor = .notesCardBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.borderColor = UIColor.notesBorder.cgColor
        containerView.layer.borderWidth = 1
        contentView.addSubview(containerView)
        
        selectImageView.contentMode = .scaleAspectFit
        selectImageView.tintColor = .notesAccent
        selectImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(selectImageView)
        
        contentWrapper.backgroundColor = .clear
        contentWrapper.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentWrapper)
        
        dateLabel.font = .systemFont(ofSize: 13, weight: .medium)
        dateLabel.textColor = .secondaryLabel
        
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        
        var playConfig = UIButton.Configuration.filled()
        playConfig.baseBackgroundColor = .notesAccent
        playConfig.baseForegroundColor = .black
        playConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        playButton = UIButton(configuration: playConfig)
        playButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        playButton.layer.cornerRadius = 16
        playButton.clipsToBounds = true
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        
        let actionStack = UIStackView(arrangedSubviews: [starButton, transcriptButton, editButton, shareButton, optionsButton])
        actionStack.axis = .horizontal
        actionStack.spacing = 16
        actionStack.distribution = .equalSpacing
        
        [starButton, transcriptButton, editButton, shareButton, optionsButton].forEach {
            $0.tintColor = .notesAccent
            $0.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
        }
        
        starButton.setImage(UIImage(systemName: "star"), for: .normal)
        transcriptButton.setImage(UIImage(systemName: "doc.text"), for: .normal)
        editButton.setImage(UIImage(systemName: "pencil.circle"), for: .normal)
        shareButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        optionsButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        
        starButton.addTarget(self, action: #selector(starTapped), for: .touchUpInside)
        transcriptButton.addTarget(self, action: #selector(transcriptTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(colorTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        optionsButton.addTarget(self, action: #selector(optionsTapped), for: .touchUpInside)
        
        contentWrapper.addSubview(dateLabel)
        contentWrapper.addSubview(titleLabel)
        contentWrapper.addSubview(playButton)
        contentWrapper.addSubview(actionStack)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        
        selectWidthConstraint = selectImageView.widthAnchor.constraint(equalToConstant: 0)
        selectTrailingConstraint = contentWrapper.leadingAnchor.constraint(equalTo: selectImageView.trailingAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            selectImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            selectImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            selectWidthConstraint,
            selectImageView.heightAnchor.constraint(equalToConstant: 24),
            
            selectTrailingConstraint,
            contentWrapper.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentWrapper.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentWrapper.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: contentWrapper.topAnchor, constant: 16),
            dateLabel.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor, constant: 16),
            
            titleLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor, constant: -16),
            
            playButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            playButton.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor, constant: 16),
            playButton.bottomAnchor.constraint(equalTo: contentWrapper.bottomAnchor, constant: -16),
            playButton.heightAnchor.constraint(equalToConstant: 32),
            
            actionStack.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            actionStack.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with recording: Recording, isPlaying: Bool, isSelectionMode: Bool, isSelected: Bool) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        dateLabel.text = formatter.string(from: recording.createdAt)
        
        titleLabel.text = recording.title
        titleLabel.textColor = recording.titleColorHex != nil ? recording.titleColor : .label
        
        let playIcon = isPlaying ? "pause.fill" : "play.fill"
        var config = playButton.configuration ?? UIButton.Configuration.filled()
        config.image = UIImage(systemName: playIcon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12))
        config.title = "  " + timeString(from: recording.duration)
        config.baseBackgroundColor = .notesAccent
        config.baseForegroundColor = .black
        playButton.configuration = config
        
        starButton.setImage(UIImage(systemName: recording.isStarred ? "star.fill" : "star"), for: .normal)
        starButton.tintColor = recording.isStarred ? .systemYellow : .notesAccent
        
        // Multi-selection animations & styling
        if isSelectionMode {
            selectWidthConstraint.constant = 24
            selectTrailingConstraint.constant = 12
            selectImageView.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            selectImageView.tintColor = isSelected ? .notesAccent : .secondaryLabel
            
            // Disable inside interaction so click targets row selection
            playButton.isUserInteractionEnabled = false
            starButton.isUserInteractionEnabled = false
            transcriptButton.isUserInteractionEnabled = false
            editButton.isUserInteractionEnabled = false
            shareButton.isUserInteractionEnabled = false
            optionsButton.isUserInteractionEnabled = false
        } else {
            selectWidthConstraint.constant = 0
            selectTrailingConstraint.constant = 0
            selectImageView.image = nil
            
            playButton.isUserInteractionEnabled = true
            starButton.isUserInteractionEnabled = true
            transcriptButton.isUserInteractionEnabled = true
            editButton.isUserInteractionEnabled = true
            shareButton.isUserInteractionEnabled = true
            optionsButton.isUserInteractionEnabled = true
        }
        
        // Perform quick layout animation update if called in animation block
        containerView.layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.borderColor = UIColor.notesBorder.cgColor
    }
    
    private func timeString(from time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "00:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @objc private func playTapped()       { delegate?.didTapPlay(for: self) }
    @objc private func starTapped()       { delegate?.didTapStar(for: self) }
    @objc private func transcriptTapped() { delegate?.didTapTranscript(for: self) }
    @objc private func colorTapped()      { delegate?.didTapColor(for: self) }
    @objc private func optionsTapped()    { delegate?.didTapOptions(for: self) }
    @objc private func shareTapped()      { delegate?.didTapShare(for: self) }
}
