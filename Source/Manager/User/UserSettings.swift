import Foundation



/**
 This is a customization point for the way the SDK behaves internally for some cases. Only mess around in here if
 you know what you're doing.

 This is a singleton and is threadsafe.
*/
public class UserSettings {
    /// Shared instance
    public static let shared = UserSettings()
    init() {}

    private let queue = DispatchQueue(label: "com.schibsted.identity.UserSettings")

    /// Set or get `UserSettings.AgreementsCache` related settings data
    public var agreementsCache: AgreementsCache {
        get {
            return self.queue.sync {
                return self._agreementsCache
            }
        }
        set(newValue) {
            self.queue.sync {
                self._agreementsCache = newValue
            }
        }
    }
    private var _agreementsCache = AgreementsCache()
}
