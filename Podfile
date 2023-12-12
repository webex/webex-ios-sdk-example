platform :ios, '12.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'KitchenSink' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for KitchenSink
	pod 'WebexSDK','~> 3.10.1'
  # pod 'WebexSDK/Meeting','~> 3.10.1'  # Uncomment this line and comment the above line for Meeting-only SDK
  # pod 'WebexSDK/Wxc','~> 3.10.1'  # Uncomment this line and comment the above line for Calling-only SDK


  target 'KitchenSinkUITests' do
  # Pods for testing
  end

end

target 'KitchenSinkBroadcastExtension' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for KitchenSinkBroadcastExtension 
  pod 'WebexBroadcastExtensionKit','~> 3.10.1'
  
end

post_install do |installer|
 installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
   config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
  end
 end
end
