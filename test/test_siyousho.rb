# frozen_string_literal: true

require 'test_helper'

class TestSiyousho < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Siyousho::VERSION
  end

  def test_output_root_defaults_to_tmp_under_the_current_directory_outside_rails
    refute defined?(Rails), 'this test assumes Rails is not loaded'
    Siyousho.output_root = nil
    assert_equal Pathname.pwd.join('tmp', '仕様書'), Siyousho.output_root
  end

  def test_output_root_can_be_configured
    Siyousho.output_root = Pathname('/elsewhere')
    assert_equal Pathname('/elsewhere'), Siyousho.output_root
  ensure
    Siyousho.output_root = nil
  end

  def test_can_be_required_before_minitest
    run = FixtureRunner.run('require_order')
    assert_predicate run.status, :success?, run.output
    assert_equal '1 runs, 1 assertions, 0 failures, 0 errors, 0 skips', run.summary
  end
end
