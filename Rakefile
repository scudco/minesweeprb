# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec
task ci: :spec

desc 'Release a new version (e.g., rake release_gem[0.5.0])'
task :release_gem, [:version] do |_t, args|
  version = args[:version]
  abort 'Usage: rake release_gem[VERSION]' unless version

  version_file = 'lib/minesweeprb/version.rb'
  content = File.read(version_file)
  new_content = content.sub(/VERSION = '.*'/, "VERSION = '#{version}'")
  abort 'VERSION not found in version.rb' if content == new_content

  File.write(version_file, new_content)
  sh "git add #{version_file}"
  sh "git commit -m 'Bump version to #{version}'"
  sh "git tag v#{version}"
  sh 'git push --tags'
  sh 'git push'

  prerelease = version.match?(/[a-zA-Z]/)
  flags = prerelease ? '--prerelease' : ''
  sh "gh release create v#{version} --title 'v#{version}' --generate-notes #{flags}"
end
