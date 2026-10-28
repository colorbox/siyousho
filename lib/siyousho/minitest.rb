# frozen_string_literal: true

require 'minitest'
require_relative 'instrumenter'
require_relative 'recorder'

module Siyousho
  # Include into a Minitest test class to record a document for each of its
  # tests. Rails system tests get it automatically (see lib/siyousho.rb).
  module Minitest
    def self.included(base)
      base.prepend(Run)
    end

    # Wraps Minitest::Test#run: for this run the test method is replaced by
    # its instrumented body, and the document is written afterwards.
    module Run
      def run
        @siyousho_recorder = Recorder.new(test_class_name: self.class.name || 'AnonymousTest',
                                          test_name: name, root: Siyousho.output_root)
        @siyousho_recorder.prepare
        replace_test_method_with_instrumented_body
        super
      ensure
        @siyousho_recorder&.finish(skipped: skipped?)
      end

      private

      # Instrumentation happens inside the replaced method, so that a source
      # that cannot be instrumented is reported as an error of that test.
      def replace_test_method_with_instrumented_body
        original = method(name)
        define_singleton_method(name) do
          instrumented = Instrumenter.instrument(original)
          instance_eval(instrumented.code, instrumented.file, instrumented.line)
        end
      end

      def __siyousho_step__(label)
        @siyousho_recorder.step(label)
      end
    end
  end
end
