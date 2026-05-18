import UIKit

class SplashViewController: UIViewController {
    
    private var containerStack: UIStackView!
    private var speakLabel: UILabel!
    private var saveLabel: UILabel!
    private var reliveLabel: UILabel!
    private var brandingIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .notesBackground
        
        setupUI()
        animateSequence()
    }
    
    private func setupUI() {
        let brandIcon = UIImageView()
        brandIcon.image = UIImage(systemName: "waveform.circle.fill")
        brandIcon.tintColor = .notesAccent
        brandIcon.contentMode = .scaleAspectFit
        brandIcon.translatesAutoresizingMaskIntoConstraints = false
        brandIcon.alpha = 0
        brandIcon.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        view.addSubview(brandIcon)
        brandingIcon = brandIcon
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        containerStack = stack
        
        let spk = UILabel()
        spk.text = "Speak."
        spk.font = .systemFont(ofSize: 32, weight: .bold)
        spk.textColor = .label
        spk.alpha = 0
        speakLabel = spk
        
        let sve = UILabel()
        sve.text = "Save."
        sve.font = .systemFont(ofSize: 32, weight: .bold)
        sve.textColor = .label
        sve.alpha = 0
        saveLabel = sve
        
        let rlv = UILabel()
        rlv.text = "Relive."
        rlv.font = .systemFont(ofSize: 36, weight: .black)
        rlv.textColor = .notesAccent
        rlv.alpha = 0
        rlv.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        reliveLabel = rlv
        
        containerStack.addArrangedSubview(speakLabel)
        containerStack.addArrangedSubview(saveLabel)
        containerStack.addArrangedSubview(reliveLabel)
        
        NSLayoutConstraint.activate([
            brandingIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            brandingIcon.bottomAnchor.constraint(equalTo: containerStack.topAnchor, constant: -24),
            brandingIcon.widthAnchor.constraint(equalToConstant: 80),
            brandingIcon.heightAnchor.constraint(equalToConstant: 80),
            
            containerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func animateSequence() {
        // Step 1: Fade-in and scale up branding icon
        UIView.animate(withDuration: 0.6, delay: 0.1, options: .curveEaseOut, animations: {
            self.brandingIcon.alpha = 1.0
            self.brandingIcon.transform = .identity
        }, completion: nil)
        
        // Step 2: Fade-in Speak label
        UIView.animate(withDuration: 0.4, delay: 0.4, options: .curveEaseOut, animations: {
            self.speakLabel.alpha = 1.0
        }, completion: nil)
        
        // Step 3: Fade-in Save label
        UIView.animate(withDuration: 0.4, delay: 0.7, options: .curveEaseOut, animations: {
            self.saveLabel.alpha = 1.0
        }, completion: nil)
        
        // Step 4: Scale and Fade-in Relive label with bounce
        UIView.animate(withDuration: 0.6, delay: 1.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.reliveLabel.alpha = 1.0
            self.reliveLabel.transform = .identity
        }) { _ in
            // Step 5: Transition to Main screen after a tiny hold
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.transitionToMain()
            }
        }
    }
    
    private func transitionToMain() {
        guard let window = self.view.window else { return }
        
        let mainVC = MainViewController()
        let rootVC = UINavigationController(rootViewController: mainVC)
        
        // Custom cross-dissolve transition
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = rootVC
        }, completion: nil)
    }
}
