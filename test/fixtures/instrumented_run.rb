# frozen_string_literal: true

# Runs one Minitest test with siyousho loaded, against a stubbed Rails.root and
# Capybara session. test_siyousho.rb executes this file in a child process and
# inspects the document written under SIYOUSHO_TEST_ROOT.
require 'fileutils'
require 'pathname'

module Rails
  def self.root
    Pathname.new(ENV.fetch('SIYOUSHO_TEST_ROOT'))
  end
end

module Capybara
  class FakeSession
    PNG_HEADER = "\x89PNG\r\n\x1a\n".b

    def save_screenshot(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.binwrite(path, PNG_HEADER)
    end
  end

  def self.current_session
    @current_session ||= FakeSession.new
  end
end

require 'minitest/autorun'
require 'siyousho'

puts "minitest #{Minitest::VERSION}"

class InstrumentedRun < Minitest::Test
  def test_steps
    a = 1
    b = a + 1
    assert_equal 2, b
    assert_kind_of Integer, b
  end
end
