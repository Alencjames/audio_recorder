require 'xcodeproj'

project_name = 'AudioRecorderApp'
project_path = "#{project_name}.xcodeproj"

# Create a new Xcode project
project = Xcodeproj::Project.new(project_path)

# Create an app target
app_target = project.new_target(:application, project_name, :ios, '16.0')

# Create a group for the main files
main_group = project.main_group.new_group(project_name)

# Add files to the group and the target's source build phase
def add_files_to_group(project, target, group, path)
  Dir.glob("#{path}/**/*.swift").each do |file_path|
    file_ref = group.new_reference(file_path)
    target.source_build_phase.add_file_reference(file_ref)
  end
end

add_files_to_group(project, app_target, main_group, '.')

# Configure Build Settings
app_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.example.#{project_name}"
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1' # iPhone
  config.build_settings['DEVELOPMENT_TEAM'] = '' # Needs to be set for device, but OK for simulator
  
  # For modern SwiftUI projects without Info.plist
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['INFOPLIST_KEY_NSMicrophoneUsageDescription'] = 'This app requires microphone access to record audio.'
  config.build_settings['INFOPLIST_KEY_NSSpeechRecognitionUsageDescription'] = 'This app uses speech recognition to generate text transcripts of your audio recordings.'
  config.build_settings['INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
end

project.save
puts "Successfully generated #{project_path}"
