import SchibstedAccount
import UIKit

struct ConfigurationLoader {
    let clientID: String
    let clientSecret: String
    let clientScheme: String

    init() {
        guard let configURL = Bundle.main.url(forResource: "ClientConfiguration", withExtension: "json") else {
            preconditionFailure(
                "The example app uses parameters that need to be decrypted. Please see readme for information on how to get client credentials"
            )
        }

        guard
            let jsonData = (try? JSONSerialization.jsonObject(with: Data(contentsOf: configURL)))
                as? [String: [String: [String: String]]],
            let configurations = jsonData["configurations"]
            else {
            preconditionFailure("Failed to get json data out of ClientConfiguration.json")
        }

        let name = "ios-default"

        self.clientID = configurations[name]?["clientID"] ?? ""
        self.clientSecret = configurations[name]?["clientSecret"] ?? ""
        self.clientScheme = configurations[name]?["clientScheme"] ?? ""
    }
}

extension SchibstedAccount.ClientConfiguration {
    static let config = ConfigurationLoader()

    static let iosDefault = {
        return ClientConfiguration(
            environment: .preproduction,
            clientID: config.clientID,
            clientSecret: config.clientSecret,
            appURLScheme: config.clientScheme
        )
    }()

    static let current = SchibstedAccount.ClientConfiguration.iosDefault
}

extension IdentityUIConfiguration {
    static let `default`: IdentityUIConfiguration = {
        let clientConfiguration: SchibstedAccount.ClientConfiguration = .current
        return IdentityUIConfiguration(clientConfiguration: clientConfiguration, theme: .default)
    }()
    
    static let current = IdentityUIConfiguration.default
}

extension AppDelegate: IdentityUIDelegate {
    func didFinish(result: IdentityUIResult) {
        switch result {
        case .canceled:
            print("The user canceled the login process")
        case let .completed(user):
            self.user = user
            self.showAlert(for: .loggedIn)
            self.updateUserLabel()
        }
    }
}

extension AppDelegate: UserDelegate {
    func user(_: User, didChangeStateTo newState: UserState) {
        print("user is \(newState)")
        self.showAlert(for: newState)
        self.updateUserLabel()
    }
}

extension UIApplication {
    var user: User? {
        return (self.delegate as? AppDelegate)?.user
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func showAlert(for state: UserState) {
        let message: String
        switch state {
        case .loggedIn:
            message = "Welcome 🎉"
        case .loggedOut:
            message = "Traitor 👹"
        }

        let alert = UIAlertController(title: "Mood", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func updateUserLabel() {
        ((self.window?.rootViewController as? UINavigationController)?.topViewController as? ViewController)?.updateUserLabel()
    }

    var window: UIWindow?
    var identityUI: IdentityUI?

    var user: User? {
        didSet {
            self.user?.delegate = self
        }
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.user = IdentityManager(clientConfiguration: .current).currentUser
        return true
    }

    func application(_: UIApplication, open url: URL, options _: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let route = IdentityUI.Route(url: url, configuration: .current) else {
            return false
        }

        guard let vc = self.window?.rootViewController else {
            return false
        }

        self.identityUI = IdentityUI(configuration: .default)
        self.identityUI?.delegate = self
        self.identityUI?.presentIdentityProcess(from: vc, route: route)

        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
