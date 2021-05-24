# Cisco Webex iOS SDK Example

This *Kitchen Sink* demo employs Cisco Webex service through [Webex iOS SDK](https://github.com/webex/webex-ios-sdk).  It provides a developer friendly sample implementation of Webex client SDK and showcases all SDK features. It focuses on how to call and use *Webex-SDK* APIs. Developers could directly cut, paste, and use the code from this sample.

This demo supports iOS device with **iOS 13** or later

## Table of Contents

- [Download App](#download-app)
- [Setup](#setup)
- [Usage](#usage)
- [API Reference](#api-reference)


## Screenshots 
<ul>
<img src="images/Picture1.png" width="22%" height="23%">
<img src="images/Picture2.png" width="22%" height="20%">
<img src="images/Picture3.png" width="22%" height="23%">
<img src="images/Picture4.png" width="22%" height="23%">
<img src="images/Picture5.png" width="22%" height="23%">
<img src="images/Picture6.png" width="22%" height="23%">
<img src="images/Picture7.png" width="22%" height="23%">
<img src="images/Picture8.png" width="22%" height="23%">
</ul>

1. ScreenShot-1: Main page of Application, listing main functions of this demo.
1. ScreenShot-2: Initiate call page.
1. ScreenShot-3: Show call controls when call is connected.
1. ScreenShot-4: Video calling screen 
1. ScreenShot-5: Teams listing screen
1. ScreenShot-6: Space listing screen
1. ScreenShot-7: Space related option screen
1. ScreenShot-8: Send Message screen

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

## Usage
 
1. Add **Secrets.plist** file in your project and add following fields:
    ```
    clientId
    clientSecret
    redirectUri
   ```
   <img src="images/secrets.png" width="80%" height="80%">

1. Enabling and using screen share on your iPhone

    - Add screen recording to control center:

      1. Open Settings -> Control Center -> Customize Controls

      1. Tap '+' on Screen Recording

    - To share your screen in KitchenSink:

      1. Swipe up to open Control Center

      1. Long press on recording button

      1. select the KitchenSinkBroadcastExtension, tap Start Broadcast button

## API Reference
For complete API Reference, see [documentation](https://webex.github.io/webex-ios-sdk/)