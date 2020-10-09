#
# Be sure to run `pod lib lint SchibstedAccount.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'SchibstedAccount'
  s.version = '2.7.1'
  s.summary = "SDK for a Schibsted identity service"
  s.license = { :type => "MIT" }
  s.homepage = "https://schibsted.github.io/account-sdk-ios/"
  s.authors = {
    "Schibsted" => "schibstedaccount@schibsted.com",
  }
  s.source = {
    :git => 'https://github.com/schibsted/account-sdk-ios.git',
    :tag => s.version.to_s
  }

  s.swift_versions = ['4.2']
  s.ios.deployment_target = '11.0'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }
  s.default_subspecs = ['Manager', 'UI']

  s.subspec "Core" do |ss|
    ss.source_files = ['Source/Core/**/*.swift']
  end

  s.subspec "Manager" do |ss|
    ss.source_files = ['Source/Manager/**/*.{h,m,swift}']
    ss.resources = ['Source/Manager/Configuration.plist']
    ss.dependency 'SchibstedAccount/Core'
  end

  s.subspec "UI" do |ss|
    ss.source_files = ['Source/UI/**/*.swift']
    ss.resources = ['Source/UI/**/*.{lproj,storyboard,xcassets,xib,strings}']
    ss.dependency 'SchibstedAccount/Manager'
  end

end
