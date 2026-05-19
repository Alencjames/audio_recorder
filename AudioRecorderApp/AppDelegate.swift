import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let splashVC = SplashViewController()
        
        // Globally read theme preference, default to dark mode!
        let isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
        window?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        
        // Globally apply Notes app yellow/gold accent tint
        window?.tintColor = .notesAccent
        
        // Customise Navigation Bar appearance globally to blend perfectly with Notes theme
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .notesBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = .notesAccent
        
        window?.rootViewController = splashVC
        window?.makeKeyAndVisible()
        
        return true
    }
}

// MARK: - Apple Notes Style Pure Black Theme Colour Palette
extension UIColor {
    /// Apple Notes signature warm Gold/Amber accent
    static let notesAccent = UIColor(red: 229/255, green: 172/255, blue: 56/255, alpha: 1.0) // #E5AC38
    
    /// Dynamic main app background color
    static var notesBackground: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .black : UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1.0)
        }
    }
    
    /// Dynamic card/cell background color
    static var notesCardBackground: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(red: 18/255, green: 18/255, blue: 20/255, alpha: 1.0) : .white
        }
    }
    
    /// Dynamic subtle border/divider color
    static var notesBorder: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .clear : UIColor(red: 230/255, green: 230/255, blue: 235/255, alpha: 1.0)
        }
    }
}
