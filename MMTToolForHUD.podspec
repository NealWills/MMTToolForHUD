Pod::Spec.new do |s|
  s.name             = 'MMTToolForHUD'
  s.version          = '0.6.3'
  s.summary          = 'A lightweight, thread-safe HUD library for iOS 13+ supporting toast, loading and progress.'

  s.description      = <<-DESC
MMTToolForHUD is a lightweight, thread-safe HUD library for iOS 13+.

It provides stackable toasts (top / center / bottom, with success, error
and info icons), loading spinners with optional text, bar and ring
progress indicators with live updates, and auto-dismissing success /
error status flashes.

Everything is managed per window, so multiple windows can display
independent HUDs and toasts, and every API is callable from any thread.
The appearance and behavior are fully customizable through a single
MMTToolForHUDConfig value. Stable accessibility identifiers are exposed
for XCUITest and Appium automation.
                       DESC

  s.homepage         = 'https://github.com/NealWills/MMTToolForHUD'
  s.documentation_url = 'https://github.com/NealWills/MMTToolForHUD/blob/main/README.md'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'nealwills' => 'nealwills93@gmail.com' }
  s.source           = { :git => 'https://github.com/NealWills/MMTToolForHUD.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.0'

  s.source_files     = 'MMTToolForHUD/Classes/**/*'
  s.frameworks       = 'UIKit'
end
