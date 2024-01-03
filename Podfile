platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'DansMaRue' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for DansMaRue
  pod 'GoogleMaps'
  pod 'GooglePlaces'
  pod 'SwiftyJSON'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'SDWebImage'
  pod 'TTGSnackbar'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  # pod 'AdtagLocationDetection', '3.1.7'
  pod 'AppAuth'

  target 'DansMaRueTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
                  xcconfig_path = config.base_configuration_reference.real_path
                  xcconfig = File.read(xcconfig_path)
                  xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
                  File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
               end
          end
   end
end
