# frozen_string_literal: true

require_relative 'fixture_env'
require 'minitest/autorun'

EVENTS = []

class InstrumentedTests < Minitest::Test
  include Siyousho::Minitest

  def before_setup
    super
    EVENTS << [name, :before_setup]
  end

  def setup
    @greeting = 'hello'
    EVENTS << [name, :setup]
  end

  def after_setup
    super
    EVENTS << [name, :after_setup]
  end

  def before_teardown
    super
    EVENTS << [name, :before_teardown]
  end

  def teardown
    EVENTS << [name, :teardown]
  end

  def after_teardown
    super
    EVENTS << [name, :after_teardown]
  end

  def test_passes
    EVENTS << [name, :body]
    greeting = "#{@greeting}, it's #{1 + 1} < 3 & true"
    # a comment between statements
    [1, 2].each do |i|
      assert i.positive?
    end
    text = <<~TEXT
      multi
      line
    TEXT
    assert_equal "hello, it's 2 < 3 & true", greeting
    assert_equal "multi\nline\n", text
  end

  def test_fails_midway
    a = 1
    assert_equal 2, a
    assert true
  end

  def test_raises_midway
    a = 1
    raise 'boom'
    assert a
  end

  def test_skipped
    skip 'later'
    assert true
  end

  def test_single_statement
    assert true
  end

  def test_empty
  end

  def test_endless = assert(true)

  def test_日本語のテスト名
    a = 1
    assert_equal 1, a
  end

  def test_with_rescue
    assert true
  rescue StandardError
    nil
  end

  class_eval <<~RUBY, '(eval)', 1
    def test_defined_by_eval
      assert true
    end
  RUBY
end

class OtherTests < Minitest::Test
  include Siyousho::Minitest

  def test_passes
    a = 2
    assert_equal 2, a
  end
end

class PlainTests < Minitest::Test
  def test_not_instrumented
    a = 1
    assert_equal 1, a
  end
end

class RailsStyleTests < Minitest::Test
  include Siyousho::Minitest

  def self.test(name, &block)
    define_method("test_#{name.gsub(/\s+/, '_')}", &block)
  end

  test 'visits the page' do
    page = 'index'
    assert_equal 'index', page
  end
end

Minitest.after_run do
  puts "EVENTS: #{EVENTS.select { |test, _| test == 'test_passes' }.map(&:last).join(' ')}"
end
