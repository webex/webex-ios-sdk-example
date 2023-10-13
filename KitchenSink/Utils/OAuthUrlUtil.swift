import Foundation
class OAuthUrlUtil {
    static func url(_ url: URL, matchesRedirectUri redirectUri: String) -> Bool {
        return url.absoluteString.lowercased().contains(redirectUri.lowercased())
    }

    static func parseOauthCodeFrom(redirectUrl: URL) -> String? {
        let query = redirectUrl.queryParameters
        if let error = query["error"] {
            print(error)
        } else if let authCode = query["code"] {
            return authCode
        }
        return nil
    }
}

extension URL {
    var queryParameters: [String: String] {
        var resultParameters = [String: String]()
        let pairs = self.query?.components(separatedBy: "&") ?? []

        for pair in pairs {
            let kv = pair.components(separatedBy: "=")
            resultParameters.updateValue(kv[1], forKey: kv[0])
        }

        return resultParameters
    }
}
