# frozen_string_literal: true

# Run with SIYOUSHO_FIXTURE_FAIL_AT=2: the second screenshot raises.
require_relative 'fixture_env'
require 'minitest/autorun'

class ScreenshotFailureTests < Minitest::Test
  include Siyousho::Minitest

  def test_steps
    a = 1
    b = a + 1
    assert_equal 2, b
  end
end
