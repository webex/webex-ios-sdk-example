source 'https://github.com/CocoaPods/Specs.git'


use_frameworks!

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          if Gem::Version.new('10.0') > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
          end
        end
      end
end


target 'KitchenSink' do
    platform :ios, '11.0'
    pod 'WebexSDK'
    pod 'Cosmos', '~> 15.0'
    pod 'Toast-Swift', '~> 5.0.0'
    pod 'FontAwesome.swift','~> 1.8.2'
end


target 'KitchenSinkBroadcastExtension' do
    platform :ios, '11.2'
    pod 'WebexBroadcastExtensionKit'
end
