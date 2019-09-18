platform :ios, "12.2"
use_frameworks!
inhibit_all_warnings!

target 'TurnUp' do
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Firebase/Firestore'
  pod 'FirebaseUI/Storage'
  pod 'BTNavigationDropdownMenu'
  
target 'TurnUpTests' do
    inherit! :search_paths
  end
  
  post_install do |installer|
      installer.pods_project.targets.each do |target|
      end
  end
end
