# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'tmpdir'

class TestSiyousho < Minitest::Test
  REPO_ROOT = File.expand_path('..', __dir__)

  def test_that_it_has_a_version_number
    require 'siyousho/version'
    refute_nil ::Siyousho::VERSION
  end

  # siyousho patches Minitest::Test#run, so it cannot be loaded into this
  # process without instrumenting these tests too. Run it in a child process
  # (same bundle, hence the same Minitest version) and inspect the output.
  def test_generates_a_document_with_a_screenshot_per_statement
    Dir.mktmpdir do |root|
      output, status = run_instrumented_fixture(root)
      assert_predicate status, :success?, output
      assert_includes output, "minitest #{Minitest::VERSION}", 'child process must use the same Minitest'
      assert_match(/1 runs, 2 assertions, 0 failures, 0 errors/, output)
      assert_document File.join(root, 'tmp', '仕様書')
    end
  end

  private

  def run_instrumented_fixture(root)
    Open3.capture2e(
      { 'SIYOUSHO_TEST_ROOT' => root },
      RbConfig.ruby, '-Ilib', 'test/fixtures/instrumented_run.rb',
      chdir: REPO_ROOT
    )
  end

  def assert_document(doc_dir)
    html = File.read(File.join(doc_dir, 'test_steps.html'))
    assert_equal ['a = 1', 'b = a + 1', 'assert_equal(2, b)', 'assert_kind_of(Integer, b)'],
                 html.scan(%r{<h1>(.*?)</h1>}).flatten
    images = html.scan(/<img src='([^']+)'/).flatten
    assert_equal %w[test_steps/0.png test_steps/1.png test_steps/2.png test_steps/3.png], images
    images.each { |image| assert_path_exists File.join(doc_dir, image) }
  end
end
