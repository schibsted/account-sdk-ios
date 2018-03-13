#
# Be sure to run `pod lib lint SchibstedAccount.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'SchibstedAccount'
  s.version = '1.0.0-rc1'
  s.summary = "SDK for a Schibsted identity service"
  s.license = { :type => "MIT" }
  s.homepage = "https://schibsted.github.io/account-sdk-ios/"
  s.authors = {
    "Schibsted" => "support@spid.no",
  }
  s.source = {
    :git => 'https://github.com/schibsted/account-sdk-ios.git',
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '9.0'

  s.default_subspecs = ['Manager', 'UI']

  s.subspec "Core" do |ss|
    ss.source_files = ['SchibstedAccount/Core/**/*.swift']
  end

  s.subspec "Manager" do |ss|
    ss.source_files = ['SchibstedAccount/Manager/**/*.{h,m,swift}']
    ss.resources = ['SchibstedAccount/Manager/Configuration.plist']
    ss.dependency 'SchibstedAccount/Core'
  end

  s.subspec "UI" do |ss|
    ss.source_files = ['SchibstedAccount/UI/**/*.swift']
    ss.resources = ['SchibstedAccount/UI/**/*.{lproj,storyboard,xcassets,xib,strings}']
    ss.dependency 'SchibstedAccount/Manager'
  end

end
