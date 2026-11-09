#
# Be sure to run `pod lib lint MMTToolForHUD.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MMTToolForHUD'
  s.version          = '0.1.0'
  s.summary          = 'A lightweight HUD library for iOS 13+ supporting toast, loading and progress.'

  s.description      = <<-DESC
MMTToolForHUD is a lightweight, thread-safe HUD library for iOS 13+.
It supports toast messages (stackable, with success/error/info icons),
loading indicators, bar & ring progress, and auto-dismissing status flash.
Fully customizable via a single MMTHUDConfig.
                       DESC

  s.homepage         = 'https://github.com/nealwills/MMTToolForHUD'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'nealwills' => 'nealwills93@gmail.com' }
  s.source           = { :git => 'https://github.com/nealwills/MMTToolForHUD.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'MMTToolForHUD/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MMTToolForHUD' => ['MMTToolForHUD/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
