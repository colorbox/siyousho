# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'

# Don't load siyousho in the test environment to avoid Minitest conflicts
# Siyousho is meant to be used in Rails system tests, not in unit tests
