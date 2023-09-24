# frozen_string_literal: true

require_relative 'lib/siyousho/version'

Gem::Specification.new do |spec|
  spec.name = 'siyousho'
  spec.version = Siyousho::VERSION
  spec.authors = ['colorbox']
  spec.email = ['colorbox222@gmail.com']

  spec.summary = 'Automatically generates specification documents with images during E2E testing.'
  spec.description = 'The Siyousho gem is designed to facilitate End-to-End (E2E) testing by automatically generating detailed specification documents. These documents are enriched with screenshots, providing a visual context for each testing step. Ideal for developers and QA teams who require comprehensive test reports, this gem helps in capturing the state of the application at various stages of the testing cycle.'
  spec.homepage = 'https://github.com/colorbox/siyousho'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/colorbox/siyousho'
  spec.metadata['changelog_uri'] = 'https://github.com/colorbox/siyousho/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'turnip'
  spec.add_runtime_dependency 'rspec', ['>=3.0', '<4.0']

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
