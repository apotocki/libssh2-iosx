Pod::Spec.new do |s|
    s.name         = "libssh2-iosx"
    s.version      = "1.11.0.1"
    s.summary      = "LIBSSH2 is a client-side C library implementing the SSH2 protocol for macOS, iOS, and visionOS, including both arm64 and x86_64 builds for macOS, iOS Simulator, and visionOS Simulator."
    s.homepage     = "https://github.com/apotocki/libssh2-iosx"
    s.license      = "BSD-3-Clause License"
    s.author       = { "Alexander Pototskiy" => "alex.a.potocki@gmail.com" }
    s.social_media_url = "https://www.linkedin.com/in/alexander-pototskiy"
    s.osx.deployment_target = "11.0"
    s.ios.deployment_target = "13.4"
    s.osx.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.ios.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.visionos.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.static_framework = true
    s.requires_arc = false
    s.prepare_command = "sh scripts/build.sh"
    s.source       = { :git => "https://github.com/apotocki/libssh2-iosx.git", :tag => "#{s.version}" }

    s.header_mappings_dir = "frameworks/Headers"
    s.public_header_files = "frameworks/Headers/**/*.{h,H,c}"
    s.source_files = "frameworks/Headers/**/*.{h,H,c}"
    s.vendored_frameworks = "frameworks/ssh2.xcframework"
        
    #s.preserve_paths = "frameworks/**/*"
end
