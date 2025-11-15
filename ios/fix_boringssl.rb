#!/usr/bin/env ruby

# Script to fix BoringSSL-GRPC compilation issues by removing -GCC_WARN_INHIBIT_ALL_WARNINGS flag
# This flag is incorrectly interpreted as "-G CC_WARN_INHIBIT_ALL_WARNINGS" causing build errors

pods_project_path = File.join(__dir__, 'Pods', 'Pods.xcodeproj', 'project.pbxproj')

unless File.exist?(pods_project_path)
  puts "❌ Error: #{pods_project_path} not found"
  puts "   Run 'pod install' first"
  exit 1
end

puts "🔧 Fixing BoringSSL-GRPC COMPILER_FLAGS in Pods.xcodeproj..."

text = File.read(pods_project_path)
original_text = text.dup

# Replace problematic -GCC_WARN_INHIBIT_ALL_WARNINGS with proper flags
text.gsub!(
  /COMPILER_FLAGS = "-DOPENSSL_NO_ASM -GCC_WARN_INHIBIT_ALL_WARNINGS -w -DBORINGSSL_PREFIX=GRPC -fno-objc-arc";/,
  'COMPILER_FLAGS = "-DOPENSSL_NO_ASM -w -DBORINGSSL_PREFIX=GRPC -fno-objc-arc";'
)

if text != original_text
  File.open(pods_project_path, "w") { |f| f.write(text) }
  
  # Count how many replacements were made
  count = original_text.scan(/COMPILER_FLAGS = "-DOPENSSL_NO_ASM -GCC_WARN_INHIBIT_ALL_WARNINGS/).length
  
  puts "✅ Fixed #{count} COMPILER_FLAGS entries in Pods.xcodeproj"
  puts "   Removed -GCC_WARN_INHIBIT_ALL_WARNINGS flag"
else
  puts "ℹ️  No changes needed - COMPILER_FLAGS already clean"
end

puts "\n🎉 Done! You can now build your iOS app."
