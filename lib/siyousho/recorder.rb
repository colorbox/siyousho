# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require_relative 'document'

module Siyousho
  # Collects the steps of one test, takes a screenshot for each of them and
  # writes the document when the test finishes. One instance per test run.
  #
  # Output layout, relative to +root+:
  #   <TestClass>/<test_name>.html
  #   <TestClass>/<test_name>/0.png, 1.png, ...
  class Recorder
    UNSAFE_CHARS = %r{[/\\:*?"<>|\x00-\x1f]}

    attr_reader :steps, :html_path, :images_dir

    # +screenshot+ is called with the path to save each screenshot to.
    def initialize(test_class_name:, test_name:, root:, screenshot: Siyousho.method(:take_screenshot))
      @title = "#{test_class_name}##{test_name}"
      @screenshot = screenshot
      base = Pathname(root).join(*test_class_name.to_s.split('::').map { |part| sanitize(part) })
      @html_path = base.join("#{sanitize(test_name)}.html")
      @images_dir = base.join(sanitize(test_name))
      @steps = []
    end

    # Removes the output of a previous run of the same test.
    def prepare
      FileUtils.rm_rf([@html_path, @images_dir])
    end

    # Takes a screenshot and records +label+ as the next step.
    def step(label)
      FileUtils.mkdir_p(@images_dir)
      image = @images_dir.join("#{@steps.size}.png")
      @screenshot.call(image)
      @steps << Step.new(label: label, image: "#{@images_dir.basename}/#{image.basename}")
    end

    # Writes the document, unless the test was skipped or recorded no steps.
    def finish(skipped: false)
      if skipped
        FileUtils.rm_rf(@images_dir)
        return
      end
      return if @steps.empty?

      FileUtils.mkdir_p(@html_path.dirname)
      File.write(@html_path, Document.new(title: @title, steps: @steps).to_html)
    end

    private

    def sanitize(name)
      name.to_s.gsub(UNSAFE_CHARS, '_')
    end
  end
end
