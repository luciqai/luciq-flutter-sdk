Pod::Spec.new do |s|
  s.name              = 'luciq_flutter'
  s.version           = '18.0.0'
  s.summary           = 'Flutter plugin for integrating the Luciq SDK.'
  s.author            = 'Luciq'
  s.homepage          = 'https://www.luciq.ai/platforms/flutter'
  s.readme            = 'https://github.com/luciqai/luciq-flutter-sdk#readme'
  s.changelog         = 'https://pub.dev/packages/luciq_flutter/changelog'
  s.documentation_url = 'https://docs.luciq.ai/docs/flutter-overview'
  s.license           = { :file => '../LICENSE' }

  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.ios.deployment_target = '10.0'
  s.pod_target_xcconfig   = { 'OTHER_LDFLAGS' => '-framework "Flutter" -framework "LuciqSDK"'}

  s.dependency 'Flutter'
  s.dependency 'Luciq', '18.0.40'
end

