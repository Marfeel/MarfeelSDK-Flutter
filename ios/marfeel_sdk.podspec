Pod::Spec.new do |s|
  s.name             = 'marfeel_sdk'
  s.version          = '0.1.1'
  s.summary          = 'Flutter plugin for Marfeel Compass analytics SDK'
  s.homepage         = 'https://github.com/Marfeel/MarfeelSDK-Flutter'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Marfeel' => 'dev@marfeel.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platforms        = { :ios => '13.0' }
  s.dependency 'Flutter'
  s.dependency 'MarfeelSDK-iOS', '~> 2.18.9'
  s.swift_version    = '5.0'
end
