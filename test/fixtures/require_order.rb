# frozen_string_literal: true

# siyousho is required before anything else; it must load Minitest itself.
require 'siyousho'
require 'minitest/autorun'

class RequireOrderTests < Minitest::Test
  def test_loads
    assert defined?(Siyousho::Minitest)
  end
end
