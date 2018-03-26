import SchibstedAccount
import UIKit

class ViewController: UIViewController {
    @IBOutlet private weak var showTeaserSwitch: UISwitch!
    @IBOutlet weak var showLogoSwitch: UISwitch!
    @IBOutlet private weak var userLabel: UILabel!
    @IBOutlet private weak var versionLabel: UILabel!
    
    var identityUI: IdentityUI?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            self.versionLabel.text = "SDK \(SchibstedAccount.sdkVersion) — Demo App \(appVersion) (\(buildVersion))"
        }
        
        self.updateUserLabel()
    }
    
    func updateUserLabel() {
        guard let user = (UIApplication.shared.delegate as? AppDelegate)?.user else {
            return
        }
        self.userLabel.text = "User: \(user.id != nil ? String(describing: user) : "n/a")"
    }

    @IBAction func didTapLoginButton(_ sender: UIButton) {
        let loginMethod: LoginMethod
        switch sender.tag {
        case 0:
            loginMethod = .phone
        case 1:
            loginMethod = .email
        default:
            loginMethod = .password
        }

        let config: IdentityUIConfiguration
        if self.showLogoSwitch.isOn {
            var theme: IdentityUITheme = .default
            theme.titleLogo = #imageLiteral(resourceName: "logo")
            config = IdentityUIConfiguration(clientConfiguration: .current, theme: theme)
        } else {
            config = .current
        }

        let teaserText = self.showTeaserSwitch.isOn ? NSLocalizedString("This is an optional teaser text whose text can be customized.", comment: "") : nil
        self.identityUI = IdentityUI(configuration: config)
        self.identityUI?.delegate = UIApplication.shared.delegate as! AppDelegate
        self.identityUI?.presentIdentityProcess(from: self, loginMethod: loginMethod, localizedTeaserText: teaserText)
    }
    
    @IBAction func didTapOpenProfileWebPage() {
        let identityManager = self.identityUI?.identityManager ?? IdentityManager(clientConfiguration: .current)
        let accountSummaryURL = identityManager.routes.accountSummaryURL
        UIApplication.shared.openURL(accountSummaryURL)
    }

    @IBAction func didTapLogoutButton(_: Any) {
        UIApplication.shared.user?.logout()
        print("Logout done!")
    }
}
