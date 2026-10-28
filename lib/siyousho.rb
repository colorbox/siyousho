# frozen_string_literal: true

require 'pathname'
require_relative 'siyousho/version'
require_relative 'siyousho/error'
require_relative 'siyousho/instrumenter'
require_relative 'siyousho/document'
require_relative 'siyousho/recorder'
require_relative 'siyousho/minitest'

# Generates a specification document, an HTML page with a screenshot before
# every statement, from Minitest system tests.
#
#   class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
#     # Rails system tests are instrumented automatically.
#   end
#
#   class CheckoutTest < Minitest::Test
#     include Siyousho::Minitest # any other Capybara-driven test class
#   end
module Siyousho
  class << self
    attr_writer :output_root

    # Directory the documents are written to. Defaults to
    # Rails.root/tmp/仕様書, or ./tmp/仕様書 outside Rails.
    def output_root
      @output_root ||= default_output_root
    end

    # Saves a screenshot of the current Capybara session to +path+.
    def take_screenshot(path)
      Capybara.current_session.save_screenshot(path.to_s)
    end

    private

    def default_output_root
      base = defined?(Rails.root) && Rails.root ? Pathname(Rails.root) : Pathname.pwd
      base.join('tmp', '仕様書')
    end
  end
end

if defined?(ActiveSupport.on_load)
  ActiveSupport.on_load(:action_dispatch_system_test_case) { include Siyousho::Minitest }
end
