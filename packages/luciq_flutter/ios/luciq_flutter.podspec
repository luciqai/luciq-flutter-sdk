Pod::Spec.new do |s|
  s.name              = 'luciq_flutter'
  s.version           = '19.6.0'
  s.summary           = 'Flutter plugin for integrating the Luciq SDK.'
  s.author            = 'Luciq'
  s.homepage          = 'https://www.luciq.ai/platforms/flutter'
  s.readme            = 'https://github.com/luciqai/luciq-flutter-sdk#readme'
  s.changelog         = 'https://pub.dev/packages/luciq_flutter/changelog'
  s.documentation_url = 'https://docs.luciq.ai/docs/flutter-overview'
  s.license           = { :file => '../LICENSE' }

  s.source              = { :path => '.' }
  s.source_files        = 'luciq_flutter/Sources/luciq_flutter/**/*.{h,m}'
  s.public_header_files = 'luciq_flutter/Sources/luciq_flutter/include/luciq_flutter/**/*.h'

  s.ios.deployment_target = '15.4'
  s.pod_target_xcconfig   = {
    'OTHER_LDFLAGS' => '-framework "Flutter" -framework "LuciqSDK"',
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/luciq_flutter/Sources/luciq_flutter/include/luciq_flutter"'
  }

  s.dependency 'Flutter'
  s.dependency 'Luciq', '19.6.1'
end

