# frozen_string_literal: true

require 'test_helper'

# Behaviour of Siyousho::Minitest, observed from outside: the fixture suite in
# test/fixtures/suite.rb runs in a child process and these tests inspect its
# output and the documents it produced.
class TestMinitestIntegration < Minitest::Test
  PNG_HEADER = "\x89PNG\r\n\x1a\n".b
  INSTRUMENTED = 'InstrumentedTests'

  def suite
    FixtureRunner.run('suite')
  end

  def test_results_are_reported_like_plain_minitest
    refute_predicate suite.status, :success?
    assert_equal '13 runs, 11 assertions, 1 failures, 3 errors, 1 skips', suite.summary, suite.output
  end

  def test_records_a_step_with_a_screenshot_before_every_statement
    steps = suite.steps(INSTRUMENTED, 'test_passes')
    assert_equal ['EVENTS << [name, :body]',
                  "greeting = \"\#{@greeting}, it's \#{1 + 1} < 3 & true\"",
                  "[1, 2].each do |i|\n      assert i.positive?\n    end",
                  "text = <<~TEXT\n      multi\n      line\n    TEXT",
                  'assert_equal "hello, it\'s 2 < 3 & true", greeting',
                  'assert_equal "multi\nline\n", text'], steps.map(&:first)
    assert_equal (0..5).map { |i| "test_passes/#{i}.png" }, steps.map(&:last)
    steps.map(&:last).each do |image|
      assert_equal PNG_HEADER,
                   File.binread(File.join(suite.images_dir(INSTRUMENTED, 'test_passes'), File.basename(image)))
    end
  end

  def test_labels_are_html_escaped
    assert_includes suite.html(INSTRUMENTED, 'test_passes'), "it&#39;s \#{1 + 1} &lt; 3 &amp; true"
  end

  def test_setup_and_teardown_hooks_run_in_order_around_the_body
    assert_includes suite.output,
                    'EVENTS: before_setup setup after_setup body before_teardown teardown after_teardown'
  end

  def test_failing_test_keeps_the_steps_up_to_the_failure_and_reports_its_location
    assert_equal ['a = 1', 'assert_equal 2, a'], suite.labels(INSTRUMENTED, 'test_fails_midway')
    line = FixtureRunner.line_of('suite', 'assert_equal 2, a')
    assert_match(%r{InstrumentedTests#test_fails_midway \[test/fixtures/suite\.rb:#{line}\]}, suite.output)
  end

  def test_erroring_test_keeps_the_steps_up_to_the_error_and_reports_its_location
    assert_equal ['a = 1', "raise 'boom'"], suite.labels(INSTRUMENTED, 'test_raises_midway')
    line = FixtureRunner.line_of('suite', "raise 'boom'")
    assert_match(/RuntimeError: boom\n.*suite\.rb:#{line}/, suite.output)
  end

  def test_skipped_test_produces_no_document
    refute suite.document?(INSTRUMENTED, 'test_skipped')
    refute_path_exists suite.images_dir(INSTRUMENTED, 'test_skipped')
  end

  def test_single_statement_and_endless_definitions
    assert_equal ['assert true'], suite.labels(INSTRUMENTED, 'test_single_statement')
    assert_equal ['assert(true)'], suite.labels(INSTRUMENTED, 'test_endless')
  end

  def test_empty_test_passes_without_a_document
    refute suite.document?(INSTRUMENTED, 'test_empty')
    refute_match(/test_empty/, suite.output)
  end

  def test_japanese_test_names
    assert_equal ['a = 1', 'assert_equal 1, a'], suite.labels(INSTRUMENTED, 'test_日本語のテスト名')
    assert_includes suite.html(INSTRUMENTED, 'test_日本語のテスト名'), '<title>InstrumentedTests#test_日本語のテスト名</title>'
  end

  def test_unsupported_bodies_are_reported_as_errors_of_that_test_only
    assert_match(%r{InstrumentedTests#test_with_rescue:\n.*rescue/ensure clauses in a test body are not supported},
                 suite.output)
    assert_match(/InstrumentedTests#test_defined_by_eval:\n.*cannot read the source of test_defined_by_eval/,
                 suite.output)
  end

  def test_each_class_gets_its_own_directory
    assert_equal ['a = 2', 'assert_equal 2, a'], suite.labels('OtherTests', 'test_passes')
    assert_equal ['a = 1', 'assert_equal 1, a'], suite.labels(INSTRUMENTED, 'test_日本語のテスト名')
  end

  def test_rails_style_block_definitions
    assert_equal ["page = 'index'", "assert_equal 'index', page"],
                 suite.labels('RailsStyleTests', 'test_visits_the_page')
  end

  def test_classes_without_the_module_are_not_touched
    refute suite.document?('PlainTests', 'test_not_instrumented')
    assert_includes suite.output, 'screenshots: 19'
  end

  def test_screenshot_failure_is_an_error_and_keeps_the_earlier_steps
    run = FixtureRunner.run('screenshot_failure', env: { 'SIYOUSHO_FIXTURE_FAIL_AT' => '2' })
    assert_equal '1 runs, 0 assertions, 0 failures, 1 errors, 0 skips', run.summary, run.output
    assert_match(/RuntimeError: screenshot unavailable \(call 2\)/, run.output)
    assert_equal ['a = 1'], run.labels('ScreenshotFailureTests', 'test_steps')
  end
end
