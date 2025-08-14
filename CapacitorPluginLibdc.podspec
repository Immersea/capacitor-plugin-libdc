require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CapacitorPluginLibdc'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target  = '13.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
  
  # Include libdivecomputer Swift wrapper and source files
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}', 
                   'ios/Plugin/Sources/Clibdivecomputer/**/*.{h,c}',
                   'ios/Plugin/Sources/LibDCBridge/**/*.{h,m,c}',
                   'ios/Plugin/Sources/LibDCSwift/**/*.{swift}',
                   'ios/Plugin/Sources/Clibdivecomputer/src/*.{c,h}'
  
  # Exclude libdivecomputer source files that might conflict
  s.exclude_files = 'ios/Plugin/Sources/Clibdivecomputer/include/libdivecomputer/Makefile.am'
  
  # Include libdivecomputer headers
  s.public_header_files = 'ios/Plugin/Sources/Clibdivecomputer/include/**/*.h',
                          'ios/Plugin/Sources/LibDCBridge/include/**/*.h'
  
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/ios/Plugin/Sources/Clibdivecomputer/include" "$(PODS_TARGET_SRCROOT)/ios/Plugin/Sources/LibDCBridge/include" "$(PODS_TARGET_SRCROOT)/ios/Plugin/Sources/Clibdivecomputer/include/libdivecomputer" "$(PODS_TARGET_SRCROOT)/ios/Plugin/Sources/Clibdivecomputer/src"',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  
  # Frameworks
  s.frameworks = 'CoreBluetooth'
end