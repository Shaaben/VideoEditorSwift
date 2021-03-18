#
#  Be sure to run `pod spec lint VideoEditorSwift.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#
Pod::Spec.new do |s|
# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #
s.name          = "VideoEditorSwift"
s.version       = "1.3.0"
s.summary       = "VideoEditorSwift is a framework"
s.homepage      = "https://github.com/Shaaben"
s.description   = "VideoEditorSwift is a swift framework"
s.license       = { :type => "MIT", :file => "LICENSE" }
s.author        = { "Mohamad" => "h.mohammad@smartmobiletech.org" }
s.platform      = :ios, "12.0"
s.ios.vendored_frameworks = 'VideoEditoriOS.framework'
s.swift_version = "5"
s.source        = { :git => "https://github.com/Shaaben/VideoEditorSwift.git", :tag => "#{s.version}" }
s.exclude_files = "Classes/Exclude"
end