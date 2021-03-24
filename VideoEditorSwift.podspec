Pod::Spec.new do |spec|

  spec.platform = :ios
  spec.name          = "VideoEditorSwift"
  spec.version       = "1.4.4"
  spec.requires_arc = true
  spec.summary       = "VideoEditorSwift is a framework"
  spec.description   = <<-DESC
  A much much longer description of VideoEditorSwift.
                      DESC
  spec.homepage      = 'https://github.com/Shaaben/VideoEditorSwift'
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Mohamad" => "h.mohammad@smartmobiletech.org" }
  spec.source = { 
  :git => 'https://github.com/Shaaben/VideoEditorSwift.git', 
    :tag => spec.version.to_s 
}
  spec.framework = 'UIKit'
  spec.swift_version = '5'
  spec.ios.deployment_target = '12.0'
  spec.exclude_files = "Classes/Exclude"
  spec.ios.vendored_frameworks = 'VideoEditoriOS.framework'
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

end