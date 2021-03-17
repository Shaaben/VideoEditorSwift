Pod::Spec.new do |spec|

  spec.platform = :ios
  spec.name         = "VideoEditoriOS"
  spec.version      = "0.1.6"
  spec.requires_arc = true
  spec.summary      = "A short description of VideoEditoriOS."
  spec.description  = <<-DESC
  A much much longer description of VideoEditoriOS.
                      DESC
  spec.homepage     = 'https://github.com/Shaaben/VideoEditorIOS'
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Mohamad" => "h.mohammad@smartmobiletech.org" }
  spec.source = { 
    :git => 'https://github.com/Shaaben/VideoEditorIOS.git', 
    :tag => spec.version.to_s 
  }
  spec.framework = 'UIKit'
  spec.dependency 'Regift'
  spec.dependency 'Gallery'
  spec.dependency 'SDWebImage/GIF'
  spec.dependency 'PryntTrimmerView'
  spec.dependency 'PKHUD'
  spec.dependency 'AssetsPickerViewController'
  spec.source_files  = "VideoEditoriOS/**/*.{swift}"
  spec.swift_version = '5'
  spec.ios.deployment_target = '12.0'

end
