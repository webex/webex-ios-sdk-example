import WebexSDK

// enum to represent the UCLoginFailureReason
public enum UCLoginFailureReasonKS {
    case InternalError
    case None
    case Unknown
    case InvalidLifeCycleState
    case InvalidCertRejected
    case SSOPageLoadError
    case SSOStartSessionError
    case SSOUnknownError
    case SSOCancelled
    case SSOWebexCloudError
    case SSOCertificateError
    case SSOWhoAmIFailure
    case SSOSessionExpired
    case InvalidBrowserResponse
    case CredentialsRequired
    case CommonIdentityProvisioningUser
    case ServiceDiscoveryFailure
    case ServiceDiscoveryAuthenticationFailure
    case ServiceDiscoveryCannotConnectToCucmServer
    case ServiceDiscoveryNoCucmConfiguration
    case ServiceDiscoveryNoSRVRecordsFound
    case ServiceDiscoveryCannotConnectToEdge
    case ServiceDiscoveryNoNetworkConnectivity
    case ServiceDiscoveryUntrustedCertificate
    case ServiceDiscoveryPrimaryAuthChanged
    case ServiceDiscoveryNoUserLookup
    case ServiceDiscoveryAuthorizationModeChanged
    case ServiceDiscoveryHomeClusterChanged
    case ConnectionFailedByMRAPolicy
    case InvalidLoginCredentials
    case TokenFailure
    case ForcedSignOut
    case IPCNotResponding
    case BroadWorksDeviceFailure
    case BroadWorksSignInFailure
    case BroadWorksConfigDownloadFailure
    case BroadWorksSSOCanceled
    case BroadWorksInvalidSipUser
    case BroadWorksSipAuthenticationError
    case BroadWorksXsiAuthenticationError

    init(reason: UCLoginFailureReason) {
        switch reason {
        case .InternalError:
            self = .InternalError
        case .None:
            self = .None
        case .Unknown:
            self = .Unknown
        case .InvalidLifeCycleState:
            self = .InvalidLifeCycleState
        case .InvalidCertRejected:
            self = .InvalidCertRejected
        case .SSOPageLoadError:
            self = .SSOPageLoadError
        case .SSOStartSessionError:
            self = .SSOStartSessionError
        case .SSOUnknownError:
            self = .SSOUnknownError
        case .SSOCancelled:
            self = .SSOCancelled
        case .SSOWebexCloudError:
            self = .SSOWebexCloudError
        case .SSOCertificateError:
            self = .SSOCertificateError
        case .SSOWhoAmIFailure:
            self = .SSOWhoAmIFailure
        case .SSOSessionExpired:
            self = .SSOSessionExpired
        case .InvalidBrowserResponse:
            self = .InvalidBrowserResponse
        case .CredentialsRequired:
            self = .CredentialsRequired
        case .CommonIdentityProvisioningUser:
            self = .CommonIdentityProvisioningUser
        case .ServiceDiscoveryFailure:
            self = .ServiceDiscoveryFailure
        case .ServiceDiscoveryAuthenticationFailure:
            self = .ServiceDiscoveryAuthenticationFailure
        case .ServiceDiscoveryCannotConnectToCucmServer:
            self = .ServiceDiscoveryCannotConnectToCucmServer
        case .ServiceDiscoveryNoCucmConfiguration:
            self = .ServiceDiscoveryNoCucmConfiguration
        case .ServiceDiscoveryNoSRVRecordsFound:
            self = .ServiceDiscoveryNoSRVRecordsFound
        case .ServiceDiscoveryCannotConnectToEdge:
            self = .ServiceDiscoveryCannotConnectToEdge
        case .ServiceDiscoveryNoNetworkConnectivity:
            self = .ServiceDiscoveryNoNetworkConnectivity
        case .ServiceDiscoveryUntrustedCertificate:
            self = .ServiceDiscoveryUntrustedCertificate
        case .ServiceDiscoveryPrimaryAuthChanged:
            self = .ServiceDiscoveryPrimaryAuthChanged
        case .ServiceDiscoveryNoUserLookup:
            self = .ServiceDiscoveryNoUserLookup
        case .ServiceDiscoveryAuthorizationModeChanged:
            self = .ServiceDiscoveryAuthorizationModeChanged
        case .ServiceDiscoveryHomeClusterChanged:
            self = .ServiceDiscoveryHomeClusterChanged
        case .ConnectionFailedByMRAPolicy:
            self = .ConnectionFailedByMRAPolicy
        case .InvalidLoginCredentials:
            self = .InvalidLoginCredentials
        case .TokenFailure:
            self = .TokenFailure
        case .ForcedSignOut:
            self = .ForcedSignOut
        case .IPCNotResponding:
            self = .IPCNotResponding
        case .BroadWorksDeviceFailure:
            self = .BroadWorksDeviceFailure
        case .BroadWorksSignInFailure:
            self = .BroadWorksSignInFailure
        case .BroadWorksConfigDownloadFailure:
            self = .BroadWorksConfigDownloadFailure
        case .BroadWorksSSOCanceled:
            self = .BroadWorksSSOCanceled
        case .BroadWorksInvalidSipUser:
            self = .BroadWorksInvalidSipUser
        case .BroadWorksSipAuthenticationError:
            self = .BroadWorksSipAuthenticationError
        case .BroadWorksXsiAuthenticationError:
            self = .BroadWorksXsiAuthenticationError
        @unknown default:
            self = .None
        }
    }
}