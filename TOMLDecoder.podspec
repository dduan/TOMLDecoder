Pod::Spec.new do |spec|
  spec.name                      = "TOMLDecoder"
  spec.version                   = "0.1.5"
  spec.summary                   = "Swift Decodable support for TOML."
  spec.homepage                  = "https://github.com/dduan/TOMLDecoder"
  spec.license                   = { :type => "MIT", :file => "LICENSE.md" }
  spec.author                    = { "Daniel Duan" => "daniel@duan.ca" }
  spec.social_media_url          = "https://twitter.com/daniel_duan"
  spec.ios.deployment_target     = "8.0"
  spec.osx.deployment_target     = "10.10"
  spec.tvos.deployment_target    = "9.0"
  spec.watchos.deployment_target = "2.0"
  spec.swift_version             = '5.1'
  spec.source                    = { :git => "https://github.com/dduan/TOMLDecoder.git", :tag => "#{spec.version}" }
  spec.source_files              = "Sources/**/*.swift"
  spec.requires_arc              = true
  spec.module_name               = "TOMLDecoder"
  spec.dependency  "NetTime"         , '~> 0.2.2'
  spec.dependency  "TOMLDeserializer", '~> 0.2.4'
end
