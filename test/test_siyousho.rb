# frozen_string_literal: true

require 'test_helper'

class TestSiyousho < Minitest::Test
  def test_that_it_has_a_version_number
    require 'siyousho/version'
    refute_nil ::Siyousho::VERSION
  end

  def test_it_does_something_useful
    # This test is a placeholder
    assert true
  end
end
