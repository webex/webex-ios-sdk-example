include(BuildModule)

if (IOS_PLATFORM STREQUAL "OS")
    set(SECRET_PLIST_FILE_NAME "Secrets.plist")
    if (NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${SECRET_PLIST_FILE_NAME}")
        message(FATAL_ERROR "Secret plist file not found. Create '${CMAKE_CURRENT_SOURCE_DIR}/${SECRET_PLIST_FILE_NAME}' before running CMake configuration.")
    endif()
endif()

if (IOS_PLATFORM STREQUAL "OS")
    set(WME_FRAMEWORK_SEARCH_PATH "${CMAKE_SOURCE_DIR}/spark-client-framework/thirdparty/wme/ios/sdk/libs/Release-iphoneos")
else()
    set(WME_FRAMEWORK_SEARCH_PATH "${CMAKE_SOURCE_DIR}/spark-client-framework/thirdparty/wme/ios/sdk/libs/Release-iphonesimulator")
endif()

BuildModule(
    NAME KitchenSink
    BUNDLE_IOS
    BUNDLE_IDENTIFIER_IOS "com.webex.sdk.KitchenSinkv3"
    PLIST_FILE_IOS "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
    XCODE_ATTRIBUTES
        XCODE_ATTRIBUTE_VALIDATE_WORKSPACE YES
        XCODE_ATTRIBUTE_APPLICATION_EXTENSION_API_ONLY NO
        XCODE_ATTRIBUTE_FRAMEWORK_SEARCH_PATHS "$<TARGET_FILE_DIR:WebexSDK>/.. ${WME_FRAMEWORK_SEARCH_PATH}"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
    EMBED_FRAMEWORKS_CODE_SIGN_ON_COPY YES
    EMBED_APP_EXTENSIONS_CODE_SIGN_ON_COPY YES
    EMBED_PLUGINS_CODE_SIGN_ON_COPY YES
    BUILD_WITH_INSTALL_RPATH YES
    INSTALL_RPATH "@executable_path/Frameworks"
    EMBED_FRAMEWORKS
        WebexSDK
        WebexBroadcastExtensionKit
        "${WME_FRAMEWORK_SEARCH_PATH}/mediastores_ios.framework"
        "${WME_FRAMEWORK_SEARCH_PATH}/wbxaecodec.framework"
        "${WME_FRAMEWORK_SEARCH_PATH}/wbxaudioengine.framework"
        "${WME_FRAMEWORK_SEARCH_PATH}/util_ios.framework"
    EMBED_APP_EXTENSIONS
        KitchenSinkBroadcastExtension
    CODE_SIGN_ENTITLEMENTS
        "${CMAKE_CURRENT_SOURCE_DIR}/KitchenSink.entitlements"
    RESOURCE_FILES_IOS
        Assets.xcassets
        Base.lproj/LaunchScreen.storyboard
        Sound/call_1_1_ringback.wav
        Sound/call_1_1_ringtone.wav
        "${SECRET_PLIST_FILE_NAME}"
    FILES
        AppDelegate.swift
        Controllers/CallViewController.swift
        Controllers/ExtrasViewController.swift
        Controllers/GetMeViewController.swift
        Controllers/HomeViewController.swift
        Controllers/InitiateCall/InitiateCallViewController.swift
        Controllers/InitiateCall/ParticipantListViewController.swift
        Controllers/InitiateCall/SubTabs/CallingSpacesListViewController.swift
        Controllers/InitiateCall/SubTabs/DialCallViewController.swift
        Controllers/InitiateCall/SubTabs/HistoryCallViewController.swift
        Controllers/InitiateCall/SubTabs/SearchContactViewController.swift
        Controllers/InitiateCall/SubTabs/CalendarMeetings/CalendarMeetingsViewController.swift
        Controllers/InitiateCall/SubTabs/CalendarMeetings/CalendarMeetingDetailViewController.swift
        Controllers/InitiateCall/SubTabs/CalendarMeetings/CalendarMeetingsViewController.swift
        Controllers/InitiateCall/SubTabs/CalendarMeetings/FilterCalendarMeetingsViewController.swift
        Controllers/InitiateCall/SubTabs/CalendarMeetings/CalendarAtendeesTableViewController.swift
        Controllers/LoginViewController.swift
        Controllers/Messaging/MessagingViewController.swift
        Controllers/Messaging/NavigationItemSetupProtocol.swift
        Controllers/Messaging/SubTabs/New\ Group/MessagingSpacesViewController.swift
        Controllers/Messaging/SubTabs/PeopleViewController.swift
        Controllers/Messaging/SubTabs/PersonFormViewController.swift
        Controllers/Messaging/SubTabs/Spaces/AttachmentPreviewViewController.swift
        Controllers/Messaging/SubTabs/Spaces/ContactSearchViewController.swift
        Controllers/Messaging/SubTabs/Spaces/FilterSpacesViewController.swift
        Controllers/Messaging/SubTabs/Spaces/MessageComposerViewController.swift
        Controllers/Messaging/SubTabs/Spaces/SpaceMembershipReadStatusViewController.swift
        Controllers/Messaging/SubTabs/Spaces/SpaceMembershipViewController.swift
        Controllers/Messaging/SubTabs/Spaces/SpaceMessagesTableViewController.swift
        Controllers/Messaging/SubTabs/Teams/TeamMembershipViewController.swift
        Controllers/Messaging/SubTabs/Teams/TeamsViewController.swift
        Controllers/PushNotificationHandler.swift
        Controllers/SetupViewController.swift
        Controllers/Shared/BasicTableViewController.swift
        Controllers/WaitingCall/IncomingCallViewCell.swift
        Controllers/WaitingCall/IncomingCallViewController.swift
        Controllers/WaitingCall/ScheduledCallViewController.swift
        Controllers/WaitingCall/ScheduledMeetingTableViewCell.swift
        Controllers/Webhook/NewWebhookFormViewController.swift
        Controllers/Webhook/WebhooksViewController.swift
        KitchenSink-Bridging-Header.h
        Models/Feature.swift
        ThirdPary/SwCrypt.swift
        Utils/CallObjectStorage.swift
        Utils/ColorUtils.swift
        Utils/ConstraintsExtension.swift
        Utils/EncryptionUtils.swift
        Utils/ImageExtension.swift
        Utils/ReusableCell.swift
        Utils/String+Extension.swift
        Utils/UIAlertAction+Extensions.swift
        Utils/UIAlertController+Extensions.swift
        Utils/UILabel+Extensions.swift
        Utils/ViewUtils.swift
        Utils/FileUtils.swift
        Utils/DateUtils.swift
        Extensions/UIAlertController+Extension.swift
        Extensions/UIView+Extenstion.swift
        Views/MultiStreamSettingsView.swift
        Views/PasswordCaptchaView.swift
        Views/MediaStreamView.swift
        Views/AuxCollectionViewCell.swift
        Views/CallButton.swift
        Views/ContactTableViewCell.swift
        Views/DialButton.swift
        Views/DialPadView.swift
        Views/Dropdown.swift
        Views/FeatureCollectionViewCell.swift
        Views/MessageTableViewCell.swift
        Views/ParticipantTableViewCell.swift
        Views/SpaceTableViewCell.swift
        Views/WebhookTableViewCell.swift
        Views/VirtualBackgroundViewCell.swift
        Views/CalendarMeetingTableViewCell.swift
    DEPENDS_ON
        WebexSDK
        WebexBroadcastExtensionKit
)



add_dependencies(
    KitchenSink KitchenSinkBroadcastExtension
)
