require_relative "boot"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module DummyApp
  class Application < Rails::Application
    # Always use the defaults of whichever Rails version is installed.
    config.load_defaults Rails.gem_version.segments.first(2).join(".")
    config.eager_load = false
  end
end
