# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/test_*.rb']
end

desc 'Run the dummy Rails app system tests against this checkout (latest Rails; needs Chrome)'
task :integration do
  Dir.chdir('test/dummy_rails_app') do
    Bundler.with_unbundled_env do
      sh 'bundle install'
      sh 'bin/rails test:all'
    end
  end
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[test rubocop]
