# frozen_string_literal: true

require 'test_helper'

class TestInstrumenter < Minitest::Test
  # Evaluates instrumented code the way the Minitest integration does and
  # records the step labels.
  class Harness
    attr_reader :labels, :values

    def initialize
      @labels = []
      @values = []
    end

    def __siyousho_step__(label)
      @labels << label
    end

    def record(value)
      @values << value
    end

    def sample
      @values << :sample
    end
  end

  def instrument(source, line: 10)
    Siyousho::Instrumenter.new(source, file: 'spec.rb', line: line).instrument
  end

  def evaluate(result)
    Harness.new.tap { |harness| harness.instance_eval(result.code, result.file, result.line) }
  end

  def test_records_a_step_before_each_statement_of_a_method
    result = instrument(<<~RUBY)
      def test_x
        a = 1
        record a
      end
    RUBY
    expected = <<~RUBY.chomp
      __siyousho_step__("a = 1"); a = 1
        __siyousho_step__("record a"); record a
    RUBY
    assert_equal expected, result.code
    assert_equal 'spec.rb', result.file
    assert_equal 11, result.line
  end

  def test_instruments_a_block_definition
    result = instrument(<<~RUBY)
      test "visits the page" do
        page = 'index'
        record page
      end
    RUBY
    assert_equal ["page = 'index'", 'record page'], evaluate(result).labels
    assert_equal 11, result.line
  end

  def test_single_statement_is_one_step
    result = instrument("def test_x\n  record 1\nend\n")
    harness = evaluate(result)
    assert_equal ['record 1'], harness.labels
    assert_equal [1], harness.values
  end

  def test_empty_body_has_no_steps
    result = instrument("def test_x\nend\n")
    assert_equal '', result.code
    assert_empty evaluate(result).labels
  end

  def test_labels_keep_quotes_interpolation_and_html_characters
    result = instrument(<<~'RUBY')
      def test_x
        x = "it's #{1 + 1}"
        record x
        record 'a < b'
      end
    RUBY
    harness = evaluate(result)
    assert_equal ["x = \"it's \#{1 + 1}\"", 'record x', "record 'a < b'"], harness.labels
    assert_equal ["it's 2", 'a < b'], harness.values
  end

  def test_comments_and_blank_lines_are_kept_but_are_not_steps
    result = instrument(<<~RUBY)
      def test_x
        a = 1 # trailing

        # a comment
        record a
      end
    RUBY
    assert_equal ['a = 1', 'record a'], evaluate(result).labels
    assert_includes result.code, "# a comment\n"
  end

  def test_multi_line_statement_is_one_step_and_its_inner_statements_are_not_instrumented
    result = instrument(<<~RUBY)
      def test_x
        [1, 2].each do |i|
          record i
        end
        record :done
      end
    RUBY
    harness = evaluate(result)
    assert_equal ["[1, 2].each do |i|\n    record i\n  end", 'record :done'], harness.labels
    assert_equal [1, 2, :done], harness.values
  end

  def test_heredoc_statement_includes_its_body_in_the_label
    result = instrument(<<~RUBY)
      def test_x
        text = <<~TEXT.strip
          multi
          line
        TEXT
        record text
      end
    RUBY
    harness = evaluate(result)
    assert_equal ["text = <<~TEXT.strip\n    multi\n    line\n  TEXT", 'record text'], harness.labels
    assert_equal ["multi\nline"], harness.values
  end

  def test_heredoc_as_the_last_statement
    result = instrument(<<~RUBY)
      def test_x
        record 1
        record <<~TEXT
          last
        TEXT
      end
    RUBY
    harness = evaluate(result)
    assert_equal ['record 1', "record <<~TEXT\n    last\n  TEXT"], harness.labels
    assert_equal [1, "last\n"], harness.values
  end

  def test_endless_method_definition
    result = instrument("def test_x = record(:endless)\n")
    harness = evaluate(result)
    assert_equal ['record(:endless)'], harness.labels
    assert_equal [:endless], harness.values
    assert_equal 10, result.line
  end

  def test_preserves_line_numbers
    result = instrument(<<~RUBY, line: 20)
      def test_x

        record __LINE__
        record __LINE__
      end
    RUBY
    assert_equal [22, 23], evaluate(result).values
  end

  def test_rescue_in_the_body_is_rejected
    error = assert_raises(Siyousho::Error) do
      instrument("def test_x\n  record 1\nrescue StandardError\n  nil\nend\n")
    end
    assert_match(%r{rescue/ensure}, error.message)
  end

  def test_source_that_is_not_a_definition_is_rejected
    error = assert_raises(Siyousho::Error) { instrument("x = 1\n") }
    assert_match(/unsupported test definition: x = 1/, error.message)
  end

  def test_unparsable_source_is_rejected
    error = assert_raises(Siyousho::Error) { instrument("def test_x\n  record(\nend\n") }
    assert_match(/cannot parse/, error.message)
  end

  def test_instruments_a_real_method_from_its_source_location
    result = Siyousho::Instrumenter.instrument(Harness.instance_method(:sample))
    assert_equal __FILE__, result.file
    harness = evaluate(result)
    assert_equal ['@values << :sample'], harness.labels
    assert_equal [:sample], harness.values
  end

  def test_method_without_readable_source_is_rejected
    klass = Class.new
    klass.class_eval "def test_x
  1
end", '(eval)', 1 # rubocop:disable Style/EvalWithLocation
    error = assert_raises(Siyousho::Error) { Siyousho::Instrumenter.instrument(klass.instance_method(:test_x)) }
    assert_match(/cannot read the source of test_x/, error.message)
  end
end
