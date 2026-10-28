# frozen_string_literal: true

require 'test_helper'

class TestDocument < Minitest::Test
  def document(title: 'PagesTest#test_x', steps: [])
    Siyousho::Document.new(title: title, steps: steps).to_html
  end

  def step(label, image = 'test_x/0.png')
    Siyousho::Step.new(label: label, image: image)
  end

  def test_declares_utf8_and_shows_the_title
    html = document(title: 'PagesTest#test_日本語')
    assert html.start_with?('<!DOCTYPE html>')
    assert_includes html, '<meta charset="utf-8">'
    assert_includes html, '<title>PagesTest#test_日本語</title>'
    assert_includes html, '<h1>PagesTest#test_日本語</h1>'
  end

  def test_renders_steps_in_order_with_their_screenshots
    html = document(steps: [step('visit root_path', 'test_x/0.png'), step('click_on "Go"', 'test_x/1.png')])
    labels = html.scan(%r{<h2><code>(.*?)</code></h2>}).flatten
    images = html.scan(/<img src="([^"]+)" alt="([^"]+)">/)
    assert_equal ['visit root_path', 'click_on &quot;Go&quot;'], labels
    assert_equal [['test_x/0.png', 'step 1'], ['test_x/1.png', 'step 2']], images
  end

  def test_escapes_html_in_title_labels_and_paths
    html = document(title: 'A<B>#test_&', steps: [step("x = 'a' < \"b\" & c", 'dir/<0>.png')])
    assert_includes html, '<title>A&lt;B&gt;#test_&amp;</title>'
    assert_includes html, '<code>x = &#39;a&#39; &lt; &quot;b&quot; &amp; c</code>'
    assert_includes html, '<img src="dir/&lt;0&gt;.png"'
    refute_includes html, '<b>'
  end

  def test_keeps_multi_line_labels
    html = document(steps: [step("within('form') do\n  fill_in 'Email'\nend")])
    assert_includes html, "<code>within(&#39;form&#39;) do\n  fill_in &#39;Email&#39;\nend</code>"
    assert_includes html, 'white-space: pre-wrap'
  end

  def test_step_without_screenshot_has_no_image
    html = document(steps: [step('assert true', nil)])
    assert_includes html, '<code>assert true</code>'
    refute_includes html, '<img'
  end
end
