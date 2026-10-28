# frozen_string_literal: true

require_relative 'lib/siyousho/version'

Gem::Specification.new do |spec|
  spec.name = 'siyousho'
  spec.version = Siyousho::VERSION
  spec.authors = ['colorbox']
  spec.email = ['colorbox222@gmail.com']

  spec.summary = 'Automatically generates specification documents with images during E2E testing.'
  spec.description = <<~DESC.tr("\n", ' ').strip
    The Siyousho gem is designed to facilitate End-to-End (E2E) testing by
    automatically generating detailed specification documents. These documents
    are enriched with screenshots, providing a visual context for each testing
    step. Ideal for developers and QA teams who require comprehensive test
    reports, this gem helps in capturing the state of the application at various
    stages of the testing cycle.
  DESC
  spec.homepage = 'https://github.com/colorbox/siyousho'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/colorbox/siyousho'
  spec.metadata['changelog_uri'] = 'https://github.com/colorbox/siyousho/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Only what the gem needs at runtime; everything else (tests, the dummy
  # Rails app, CI and development configuration) stays out of the package.
  spec.files = Dir['lib/**/*.rb', 'sig/**/*.rbs', 'CHANGELOG.md', 'LICENSE.txt', 'README.md']
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'method_source', '>= 1.0'
  spec.add_dependency 'minitest', '>= 5.25', '< 7'
  spec.add_dependency 'prism', '>= 1.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
