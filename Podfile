platform :ios, "12.2"
use_frameworks!
inhibit_all_warnings!

target 'TurnUp' do
  pod 'MessageKit', '0.13.1'
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Firebase/Firestore'
  pod 'BTNavigationDropdownMenu'
  
target 'TurnUpTests' do
    inherit! :search_paths
  end
  
  post_install do |installer|
      installer.pods_project.targets.each do |target|
          if target.name == 'MessageKit'
              target.build_configurations.each do |config|
                  config.build_settings['SWIFT_VERSION'] = '4.0'
              end
          end
      end
  end
end
