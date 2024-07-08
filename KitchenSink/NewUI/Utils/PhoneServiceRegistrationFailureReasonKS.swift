import WebexSDK

//enum to represent the PhoneServiceRegistrationFailureReason
public enum PhoneServiceRegistrationFailureReasonKS {
    /// Unknown
    case Unknown
    /// None
    case None
    /// Registering
    case Registering
    /// Waiting-for-config-file
    case WaitingForConfigFile
    /// Not started
    case NotStarted
    /// No network
    case NoNetwork
    /// Failover
    case Failover
    /// Fallback
    case Fallback
    /// RegAllFailed
    case RegAllFailed
    /// Shutdown
    case Shutdown
    /// Logout reset
    case LogoutReset
    /// Invalid credentials
    case InvalidCredentials
    /// No credentials configured
    case NoCredentialsConfigured
    /// Phone-authentication-failure
    case PhoneAuthenticationFailure
    /// Phone authentication required
    case PhoneAuthenticationRequired
    /// Line registration failure
    case LineRegistrationFailure
    /// Registered elsewhere
    case RegisteredElsewhere
    /// No remote destination available
    case NoRemoteDestinationAvailable
    /// Could not activate remote destination
    case CouldNotActivateRemoteDestination
    /// No device configured
    case NoDeviceConfigured
    /// Invalid config
    case InvalidConfig
    /// Could not connect
    case CouldNotConnect
    /// Device not in service
    case DeviceNotInService
    /// Device registration timed out
    case DeviceRegTimedOut
    /// Device already registered
    case DeviceRegDeviceAlreadyRegistered
    /// Could not connect
    case DeviceRegCouldNotConnect
    /// No devices found
    case DeviceRegNoDevicesFound
    /// Authentication failure
    case DeviceRegAuthenticationFailure
    /// Selected device not found
    case DeviceRegSelectedDeviceNotFound
    /// Selected line not found
    case DeviceRegSelectedLineNotFound
    /// Could not ope device
    case DeviceRegCouldNotOpenDevice
    /// Could not open line
    case DeviceRegCouldNotOpenLine
    ///  Not authorized
    case DeviceNotAuthorised
    /// TLS failure
    case TLSFailure
    /// IP mode mismatch
    case IpModeMismatch
    /// Host resolution failure
    case HostResolutionFailure
    /// Server error
    case ServerError
    /// Require storage helper
    case RequireStorageHelper
    /// Device configuration retrieval timed out
    case DeviceConfigurationRetrievalTimedOut
    /// Edge phone mode not supported
    case EdgePhoneModeNotSupported
    /// Edge IP mode not supported
    case EdgeIpModeNotSupported
    /// No HTTP helper available
    case NoHttpHelperAvailable
    /// CTI unable to verify certificate
    case CTIUnableToVerifyCertificate
    /// FIPS no certificate verifier
    case FIPSNoCertificateVerifier
    /// No certificate verifier
    case NoCertificateVerifier
    /// P2P hybrid not supported
    case P2PHybridNotSupported
    /// Disabled by MRA policy
    case DisabledByMRAPolicy
    /// Device max connection reached
    case DeviceMaxConnectionReached
    /// Ultrasound capturer occupied
    case UltrasoundCapturerOccupied
    /// Directory login not allowed
    case DirectoryLoginNotAllowed
    
    init(reason: PhoneServiceRegistrationFailureReason) {
        switch reason {
        case .Unknown:
            self = .Unknown
        case .None:
            self = .None
        case .Registering:
            self = .Registering
        case .WaitingForConfigFile:
            self = .WaitingForConfigFile
        case .NotStarted:
            self = .NotStarted
        case .NoNetwork:
            self = .NoNetwork
        case .Failover:
            self = .Failover
        case .Fallback:
            self = .Fallback
        case .RegAllFailed:
            self = .RegAllFailed
        case .Shutdown:
            self = .Shutdown
        case .LogoutReset:
            self = .LogoutReset
        case .InvalidCredentials:
            self = .InvalidCredentials
        case .NoCredentialsConfigured:
            self = .NoCredentialsConfigured
        case .PhoneAuthenticationFailure:
            self = .PhoneAuthenticationFailure
        case .PhoneAuthenticationRequired:
            self = .PhoneAuthenticationRequired
        case .LineRegistrationFailure:
            self = .LineRegistrationFailure
        case .RegisteredElsewhere:
            self = .RegisteredElsewhere
        case .NoRemoteDestinationAvailable:
            self = .NoRemoteDestinationAvailable
        case .CouldNotActivateRemoteDestination:
            self = .CouldNotActivateRemoteDestination
        case .NoDeviceConfigured:
            self = .NoDeviceConfigured
        case .InvalidConfig:
            self = .InvalidConfig
        case .CouldNotConnect:
            self = .CouldNotConnect
        case .DeviceNotInService:
            self = .DeviceNotInService
        case .DeviceRegTimedOut:
            self = .DeviceRegTimedOut
        case .DeviceRegDeviceAlreadyRegistered:
            self = .DeviceRegDeviceAlreadyRegistered
        case .DeviceRegCouldNotConnect:
            self = .DeviceRegCouldNotConnect
        case .DeviceRegNoDevicesFound:
            self = .DeviceRegNoDevicesFound
        case .DeviceRegAuthenticationFailure:
            self = .DeviceRegAuthenticationFailure
        case .DeviceRegSelectedDeviceNotFound:
            self = .DeviceRegSelectedDeviceNotFound
        case .DeviceRegSelectedLineNotFound:
            self = .DeviceRegSelectedLineNotFound
        case .DeviceRegCouldNotOpenDevice:
            self = .DeviceRegCouldNotOpenDevice
        case .DeviceRegCouldNotOpenLine:
            self = .DeviceRegCouldNotOpenLine
        case .DeviceNotAuthorised:
            self = .DeviceNotAuthorised
        case .TLSFailure:
            self = .TLSFailure
        case .IpModeMismatch:
            self = .IpModeMismatch
        case .HostResolutionFailure:
            self = .HostResolutionFailure
        case .ServerError:
            self = .ServerError
        case .RequireStorageHelper:
            self = .RequireStorageHelper
        case .DeviceConfigurationRetrievalTimedOut:
            self = .DeviceConfigurationRetrievalTimedOut
        case .EdgePhoneModeNotSupported:
            self = .EdgePhoneModeNotSupported
        case .EdgeIpModeNotSupported:
            self = .EdgeIpModeNotSupported
        case .NoHttpHelperAvailable:
            self = .NoHttpHelperAvailable
        case .CTIUnableToVerifyCertificate:
            self = .CTIUnableToVerifyCertificate
        case .FIPSNoCertificateVerifier:
            self = .FIPSNoCertificateVerifier
        case .NoCertificateVerifier:
            self = .NoCertificateVerifier
        case .P2PHybridNotSupported:
            self = .P2PHybridNotSupported
        case .DisabledByMRAPolicy:
            self = .DisabledByMRAPolicy
        case .DeviceMaxConnectionReached:
            self = .DeviceMaxConnectionReached
        case .UltrasoundCapturerOccupied:
            self = .UltrasoundCapturerOccupied
        case .DirectoryLoginNotAllowed:
            self = .DirectoryLoginNotAllowed
        @unknown default:
            self = .Unknown
        }
    }
}