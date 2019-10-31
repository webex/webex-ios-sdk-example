# Kitchen Sink

Kitchen Sink is a developer friendly sample implementation of Webex client SDK and showcases all SDK features. It focuses on how to call and use "Webex-SDK" APIs. Developers could directly cut, paste, and use the code from this sample. It basically implements “Webex-SDK” APIs by sequence.

## Screenshots 
<ul>
<img src="https://github.com/webex/webex-ios-sdk-example/blob/master/ScreenShots/IMG_0613.jpg" width="22%" height="23%">
<img src="https://github.com/webex/webex-ios-sdk-example/blob/master/ScreenShots/IMG_0618.jpg" width="22%" height="23%">
<img src="https://github.com/webex/webex-ios-sdk-example/blob/master/ScreenShots/IMG_0614.jpg" width="22%" height="23%">
<img src="https://github.com/webex/webex-ios-sdk-example/blob/master/ScreenShots/IMG_0616.jpg" width="22%" height="23%">
</ul>

1. ScreenShot-1: Main page of Application, listing main functions of this demo.
1. ScreenShot-2: Calling room with multi-stream view.
1. ScreenShot-3: Iniciate call page, contains call recent/search/email/group.
1. ScreenShot-4: Show messaing APIs with present payloads.

## Download App
You can download our Demo App from TestFlight.
1. Download TestFlight from App Stroe.
1. Open the public url(https://testflight.apple.com/join/HWhcEPFe) from your iPhone browser.
1. Start Testing and install Ktichen Sink App from TestFlight.
## Setup
Here are the steps to setup Xcode project using [CocoaPods](http://cocoapods.org):

1. Install CocoaPods:
    ```bash
    gem install cocoapods
    ```

1. Setup Cocoapods:
    ```bash
    pod setup
    ```

1. Install WebexSDK and other dependencies from your project directory:

    ```bash
    pod install
    ```
## Example
The "// MARK: " labels in source code have distinguished the SDK calling and UI views paragraphes.  
Below is code snippets of the SDK calling in the demo.

1. Setup SDK with app infomation, and authorize access to Webex service
   ```swift
   class WebexEnvirmonment {
       static let ClientId = "your client ID"
       static let ClientSecret = ProcessInfo().environment["CLIENTSECRET"] ?? "your secret"
       static let Scope = "spark:all"
       static let RedirectUri = "KitchenSink://response"
    }
    ```

1. Register the device to send and receive calls.
    ```swift
    var webexSDK: Webex?
    /*  
    Register phone to Cisco cloud on behalf of the authenticated user.
    It also creates the websocket and connects to Cisco Webex cloud.
    - note: make sure register phone before calling
    */
    webexSDK?.phone.register() { [weak self] error in
        if let strongSelf = self {
            if error != nil {
                //success...
            } else {
                //fail...
            }
        }
    }
    ```
            
1. Webex calling API
    
   ```swift
    // Self video view and Remote video view
    @IBOutlet weak var selfView: MediaRenderView!
    @IBOutlet weak var remoteView: MediaRenderView!

    var webexSDK: Webex?
    // currentCall represents current dailing/received call instance
    var currentCall: Call?
    
    // Make an outgoing call.
    // audioVideo as making a Video call,audioOnly as making Voice only call.The default is audio call.
        var mediaOption = MediaOption.audioOnly()
        if globalVideoSetting.isVideoEnabled() {
            mediaOption = MediaOption.audioVideo(local: self.selfView, remote: self.remoteView)
        }
        // Makes a call to an intended recipient on behalf of the authenticated user.
        webexSDK?.phone.dial(remoteAddr, option: mediaOption) { [weak self] result in
            if let strongSelf = self {
                switch result {
                case .success(let call):
                    self.currentCall = call
                    // Callback when remote participant(s) is ringing.
                    call.onRinging = { [weak self] in
                        if let strongSelf = self {
                            //...
                        }
                    }
                    // Callback when remote participant(s) answered and this *call* is connected.
                    call.onConnected = { [weak self] in
                        if let strongSelf = self {
                            //...
                        }
                     }
                    //Callback when this *call* is disconnected (hangup, cancelled, get declined or other self device pickup the call).
                    call.onDisconnected = {[weak self] disconnectionType in
                        if let strongSelf = self {
                            //...
                        }
                    }
                    // Callback when the media types of this *call* have changed.
                    call.onMediaChanged = {[weak self] mediaChangeType in
                        if let strongSelf = self {
                            strongSelf.updateAvatarViewVisibility()
                            switch mediaChangeType {
                            //Local/Remote video rendering view size has changed
                            case .localVideoViewSize,.remoteVideoViewSize:
                                break
                            // This might be triggered when the remote party muted or unmuted the audio.
                            case .remoteSendingAudio(let isSending):
                                break
                            // This might be triggered when the remote party muted or unmuted the video.
                            case .remoteSendingVideo(let isSending):
                                break
                            // This might be triggered when the local party muted or unmuted the video.
                            case .sendingAudio(let isSending):
                                break
                            // This might be triggered when the local party muted or unmuted the aideo.
                            case .sendingVideo(let isSending):
                                break
                            // Camera FacingMode on local device has switched.
                            case .cameraSwitched:
                                break
                            // Whether loud speaker on local device is on or not has switched.
                            case .spearkerSwitched:
                                break
                            default:
                                break
                            }
                        }
                    }
                case .failure(let error):
                    _ = strongSelf.navigationController?.popViewController(animated: true)
                    print("Dial call error: \(error)")
                }
            }
        }
        
    // Receive a call
    if let phone = self.webex?.phone {
            // Callback when call is incoming.
            phone.onIncoming = { [weak self] call in
                if let strongSelf = self {
                    self.currentCall = call
                    //...
                }
            }
    }
    
    /* 
     Answers this call.
     This can only be invoked when this call is incoming and in rining status.
     Otherwise error will occur and onError callback will be dispatched.
     */
     self.currentCall?.answer(option: mediaOption) { [weak self] error in
         if let strongSelf = self {
             if error != nil {
                    //...
             }
         }
     }
    
    /* 
     Rejects this call. 
     This can only be invoked when this call is incoming and in rining status.
     Otherwise error will occur and onError callback will be dispatched. 
    */
    self.currentCall?.reject() { error in
            if error != nil {
                //...
            }
    }
    
    /* 
     Sharing screen in this call
    */
    self.currentCall?.oniOSBroadcastingChanged = {
        event in
        if #available(iOS 11.2, *) {
            switch event {
            case .extensionConnected :
                call.startSharing() {
                    error in
                    // ...
                }
                break
            case .extensionDisconnected:
                call.stopSharing() {
                    error in
                    // ...
                }
                break
            }
        }
    }
    
    /* 
        Using multi stream in this call.
        Implementation MultiStreamObserver protocol.
    */
    
    //set the observer of this call to get the multi stream event */
    self.currentCall?.multiStreamObserver = self
            
    //Implementation callback when a new multi stream media being available. Return a MediaRenderView let the SDK open it automatically. Return nil if you want to open it by call the API:openAuxStream(view: MediaRenderView) later.
    self.onAuxStreamAvailable = { 
        ...
        return mediaRenderView
    }
            
    //Implementation callback when an existing multi stream media being unavailable. The SDK will close the last auxiliary stream if you don't return the specified view.
    self.onAuxStreamUnavailable = {
        ...
        return nil
    }
            
    //Implementation callback when an existing multi stream media changed. */
    self.onAuxStreamChanged = {event in
        switch event {
            /* Callback for open an auxiliary stream results. */
            case .auxStreamOpenedEvent(let view, let result):
                switch result {
                    case .success(let auxStream):
                        ...
                    case .failure(let error):
                        ...
                }
            /* This might be triggered when the auxiliary stream's speaker has changed. */
            case .auxStreamPersonChangedEvent(let auxStream,_,_):
                 ...
            /* This might be triggered when the speaker muted or unmuted the video. */
            case .auxStreamSendingVideoEvent(let auxStream):
                ...
            /* This might be triggered when the speaker's video rendering view size has changed. */
            case .auxStreamSizeChangedEvent(let auxStream):
                ...
            /* Callback for close an auxiliary stream results. */
            case .auxStreamClosedEvent(let view, let error):
                ...
            }
        }
    }
    ```
1. Enable and using screen share on your iPhone

    4.1 Add screen recording to control center:
    
        4.1.1 Open Settings -> Control Center -> Customize Controls
        
        4.1.2 Tap '+' on Screen Recording
        
    4.2 To share your screen in KitchenShink:
    
        4.2.1 Swipe up to open Control Center
        
        4.2.2 Long press on recoridng button
        
        4.2.3 select the KitchenSinkBroadcastExtension, tap Start Broadcast button
# Buddies-App
Here is another demo app-"Buddies", which is more implemented as production application, combined call functionalities with CallKit, included message/call UI-implementation which could be used as widgets.
[GitHub-Buddies](https://github.com/webex/webex-ios-sdk-example-buddies)
