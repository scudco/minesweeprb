# frozen_string_literal: true

require_relative 'lib/minesweeprb/version'

Gem::Specification.new do |spec|
  spec.name          = 'minesweeprb'
  spec.license       = 'MIT'
  spec.version       = Minesweeprb::VERSION
  spec.authors       = ['scudco']
  spec.email         = ['3806+scudco@users.noreply.github.com']

  spec.summary       = 'Terminal-based Minesweeper'
  spec.homepage      = 'https://github.com/scudco/minesweeper'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added
  # into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'tty', '~> 0.10'
end
