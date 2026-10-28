# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

# Runs a fixture test file (test/fixtures/<name>.rb) in a child process, with
# the gem on the load path and SIYOUSHO_TEST_ROOT pointing at a temporary
# directory, and exposes the output and the generated documents.
module FixtureRunner
  REPO_ROOT = File.expand_path('../..', __dir__)
  ENTITIES = { '&lt;' => '<', '&gt;' => '>', '&amp;' => '&', '&quot;' => '"', '&#39;' => "'" }.freeze

  # The outcome of one fixture run.
  Run = Struct.new(:output, :status, :root, keyword_init: true) do
    def document_path(test_class, test_name)
      File.join(root, 'tmp', '仕様書', *test_class.split('::'), "#{test_name}.html")
    end

    def images_dir(test_class, test_name)
      File.join(root, 'tmp', '仕様書', *test_class.split('::'), test_name)
    end

    def document?(test_class, test_name)
      File.exist?(document_path(test_class, test_name))
    end

    def html(test_class, test_name)
      File.read(document_path(test_class, test_name))
    end

    # [[label, image], ...] in document order.
    def steps(test_class, test_name)
      page = html(test_class, test_name)
      labels = page.scan(%r{<h2><code>(.*?)</code></h2>}m).flatten.map { |label| unescape(label) }
      images = page.scan(/<img src="([^"]+)"/).flatten.map { |image| unescape(image) }
      labels.zip(images)
    end

    def labels(test_class, test_name)
      steps(test_class, test_name).map(&:first)
    end

    def summary
      output[/\d+ runs, \d+ assertions, \d+ failures, \d+ errors, \d+ skips/]
    end

    private

    def unescape(text)
      text.gsub(/&(lt|gt|amp|quot|#39);/) { ENTITIES[Regexp.last_match(0)] }
    end
  end

  # Runs the fixture once per process and keeps its output directory until exit.
  def self.run(name, env: {})
    (@runs ||= {})[[name, env]] ||= begin
      root = Dir.mktmpdir('siyousho')
      at_exit { FileUtils.rm_rf(root) }
      output, status = Open3.capture2e(
        { 'SIYOUSHO_TEST_ROOT' => root }.merge(env),
        RbConfig.ruby, '-Ilib', "test/fixtures/#{name}.rb", chdir: REPO_ROOT
      )
      Run.new(output: output, status: status, root: root)
    end
  end

  # Line number of the first line of the fixture containing +text+.
  def self.line_of(name, text)
    File.readlines(File.join(REPO_ROOT, 'test', 'fixtures', "#{name}.rb")).index { |line| line.include?(text) } + 1
  end
end
