# frozen_string_literal: true

require 'prism'
require 'method_source'
require_relative 'error'

module Siyousho
  # Rewrites the body of a test method so that a step is recorded before each
  # top-level statement. The statement's own source text becomes the label.
  class Instrumenter
    STEP_METHOD = '__siyousho_step__'

    # The instrumented code and the file and line to evaluate it at, so that
    # failure locations still point into the original test file.
    Result = Struct.new(:code, :file, :line, keyword_init: true)

    # Instruments a Method (or UnboundMethod) whose source can be located.
    def self.instrument(method)
      file, line = method.source_location
      raise Error, "cannot locate the source of #{method.name}" unless file

      new(method.source, file: file, line: line).instrument
    rescue MethodSource::SourceNotFoundError => e
      raise Error, "cannot read the source of #{method.name}: #{e.message}"
    end

    # +source+ is the full definition (`def ... end` or `test "..." do ... end`)
    # starting at +line+ of +file+.
    def initialize(source, file: '(siyousho)', line: 1)
      @source = source
      @file = file
      @line = line
    end

    def instrument
      statements = body_statements
      return Result.new(code: '', file: @file, line: @line) if statements.empty?

      first_line = statements.first.location.start_line
      Result.new(code: rewrite(statements), file: @file, line: @line + first_line - 1)
    end

    private

    # Keeps everything between statements (newlines, comments) and prefixes
    # each statement on its own line, so line numbers are preserved.
    def rewrite(statements)
      code = +''
      cursor = statements.first.location.start_offset
      statements.each do |statement|
        start = statement.location.start_offset
        finish = end_offset(statement)
        code << @source.byteslice(cursor, start - cursor) << step_call(start, finish)
        cursor = finish
      end
      code
    end

    def step_call(start, finish)
      text = @source.byteslice(start, finish - start)
      "#{STEP_METHOD}(#{text.rstrip.dump}); #{text}"
    end

    # A statement's location stops at a heredoc opening; its body and
    # terminator come after, so include them in the statement's extent.
    def end_offset(node)
      ends = node.compact_child_nodes.map { |child| end_offset(child) }
      ends << node.closing_loc.end_offset if heredoc?(node)
      ends << node.location.end_offset
      ends.max
    end

    def heredoc?(node)
      node.respond_to?(:opening_loc) && node.opening_loc&.slice&.start_with?('<<')
    end

    def body_statements
      body = definition_body
      case body
      when nil then []
      when Prism::StatementsNode then body.body
      else raise Error, 'rescue/ensure clauses in a test body are not supported'
      end
    end

    def definition_body
      result = Prism.parse(@source)
      raise Error, "cannot parse the test source: #{result.errors.map(&:message).join(', ')}" if result.failure?

      node = result.value.statements.body.first
      case node
      when Prism::DefNode then node.body
      when Prism::CallNode then block_body(node)
      else unsupported(node)
      end
    end

    def block_body(call)
      return call.block.body if call.block.is_a?(Prism::BlockNode)

      unsupported(call)
    end

    def unsupported(node)
      first_line = node ? node.slice.lines.first.strip : '(empty)'
      raise Error, "unsupported test definition: #{first_line}"
    end
  end
end
