Pod::Spec.new do |s|
  s.name           = 'FlutterPrefs'
  s.version        = '1.0.0'
  s.summary        = 'Reads values left by Flutter shared_preferences'
  s.description    = 'Reads values left by Flutter shared_preferences (NSUserDefaults, flutter. prefix)'
  s.author         = ''
  s.homepage       = 'https://github.com/pagedownq/Seydirehber'
  s.platforms      = { :ios => '16.4' }
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
end
