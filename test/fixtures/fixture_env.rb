# frozen_string_literal: true

# Shared setup for the fixture files: output under SIYOUSHO_TEST_ROOT and a
# stand-in for Capybara that writes a PNG header and counts the calls.
# siyousho is required before minitest on purpose (it must load on its own).
require 'fileutils'
require 'pathname'
require 'siyousho'

Siyousho.output_root = Pathname(ENV.fetch('SIYOUSHO_TEST_ROOT')).join('tmp', '仕様書')

module Capybara
  class FakeSession
    PNG_HEADER = "\x89PNG\r\n\x1a\n".b

    attr_reader :count

    def initialize
      @count = 0
    end

    def save_screenshot(path)
      @count += 1
      raise "screenshot unavailable (call #{@count})" if @count.to_s == ENV['SIYOUSHO_FIXTURE_FAIL_AT']

      FileUtils.mkdir_p(File.dirname(path))
      File.binwrite(path, PNG_HEADER)
    end
  end

  def self.current_session
    @current_session ||= FakeSession.new
  end
end

Minitest.after_run { puts "screenshots: #{Capybara.current_session.count}" }
