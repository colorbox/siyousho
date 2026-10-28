# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

class TestRecorder < Minitest::Test
  PNG_HEADER = "\x89PNG\r\n\x1a\n".b

  def setup
    @root = Pathname(Dir.mktmpdir('siyousho'))
    @shots = []
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def recorder(test_class_name: 'PagesTest', test_name: 'test_x', screenshot: method(:fake_screenshot))
    Siyousho::Recorder.new(test_class_name: test_class_name, test_name: test_name, root: @root, screenshot: screenshot)
  end

  def fake_screenshot(path)
    @shots << path
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, PNG_HEADER)
  end

  def test_output_layout_is_class_directory_test_html_and_test_directory
    rec = recorder(test_class_name: 'Admin::UsersTest', test_name: 'test_signing_up')
    assert_equal @root.join('Admin', 'UsersTest', 'test_signing_up.html'), rec.html_path
    assert_equal @root.join('Admin', 'UsersTest', 'test_signing_up'), rec.images_dir
  end

  def test_sanitizes_unsafe_characters_and_keeps_unicode
    rec = recorder(test_class_name: 'A:B', test_name: 'test_visit_/users?x=1 日本語')
    assert_equal @root.join('A_B', 'test_visit__users_x=1 日本語.html'), rec.html_path
  end

  def test_each_step_takes_a_numbered_screenshot_relative_to_the_document
    rec = recorder
    rec.step('visit root_path')
    rec.step('click_on "Go"')
    assert_equal [@root.join('PagesTest', 'test_x', '0.png'), @root.join('PagesTest', 'test_x', '1.png')], @shots
    assert_equal ['test_x/0.png', 'test_x/1.png'], rec.steps.map(&:image)
    assert_equal ['visit root_path', 'click_on "Go"'], rec.steps.map(&:label)
  end

  def test_finish_writes_the_document_with_the_class_and_test_name_as_title
    rec = recorder
    rec.step('visit root_path')
    rec.finish
    html = rec.html_path.read
    assert_includes html, '<title>PagesTest#test_x</title>'
    assert_includes html, '<img src="test_x/0.png"'
    assert_equal PNG_HEADER, rec.images_dir.join('0.png').binread
  end

  def test_finish_without_steps_writes_nothing
    rec = recorder
    rec.finish
    refute_path_exists rec.html_path
    refute_path_exists rec.images_dir
  end

  def test_finish_of_a_skipped_test_discards_its_screenshots
    rec = recorder
    rec.step('skip "later"')
    rec.finish(skipped: true)
    refute_path_exists rec.html_path
    refute_path_exists rec.images_dir
  end

  def test_prepare_removes_the_output_of_a_previous_run
    previous = recorder
    3.times { |i| previous.step("step #{i}") }
    previous.finish
    rec = recorder
    rec.prepare
    refute_path_exists rec.html_path
    refute_path_exists rec.images_dir
    rec.step('only step')
    rec.finish
    assert_equal(['0.png'], rec.images_dir.children.map { |path| path.basename.to_s })
  end

  def test_screenshot_errors_propagate
    rec = recorder(screenshot: ->(_path) { raise 'no driver' })
    error = assert_raises(RuntimeError) { rec.step('visit root_path') }
    assert_equal 'no driver', error.message
    assert_empty rec.steps
  end
end
