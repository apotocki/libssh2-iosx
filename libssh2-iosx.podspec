Pod::Spec.new do |s|
    s.name         = "libssh2-iosx"
    s.version      = "1.11.1.0"
    s.summary      = "libssh2 (SSH2 client library) XCFramework for macOS, iOS, watchOS, tvOS, and visionOS, with Catalyst and simulators."
    s.homepage     = "https://github.com/apotocki/libssh2-iosx"
    s.license      = "BSD-3-Clause License"
    s.author       = { "Alexander Pototskiy" => "alex.a.potocki@gmail.com" }
    s.social_media_url = "https://www.linkedin.com/in/alexander-pototskiy"
    s.ios.deployment_target = "15.0"
    s.osx.deployment_target = "12.0"
    s.tvos.deployment_target = "15.0"
    s.watchos.deployment_target = "11.0"
    s.visionos.deployment_target = "1.0"
    s.ios.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.osx.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.tvos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.watchos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.visionos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.ios.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.osx.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.tvos.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.watchos.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.visionos.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.static_framework = true
    s.requires_arc = false
    s.prepare_command = "sh scripts/build.sh"
    s.source       = { :git => "https://github.com/apotocki/libssh2-iosx.git", :tag => "#{s.version}" }

    # the default subspec adds the OpenSSL the library links against; Core leaves OpenSSL to the app
    s.default_subspecs = "OpenSSL"

    s.subspec "Core" do |core|
        core.header_mappings_dir = "frameworks/Headers"
        core.public_header_files = "frameworks/Headers/**/*.{h,H,c}"
        core.source_files = "frameworks/Headers/**/*.{h,H,c}"
        core.vendored_frameworks = "frameworks/ssh2.xcframework"
        core.libraries = "z"
    end

    s.subspec "OpenSSL" do |openssl|
        openssl.dependency "libssh2-iosx/Core"
        openssl.dependency "openssl-iosx", "~> 3.5"
    end
end
