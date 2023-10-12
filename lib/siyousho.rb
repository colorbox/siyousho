# frozen_string_literal: true

require_relative 'siyousho/version'

require 'unparser'
require 'parser/current'
require 'method_source'

module Siyousho
  class << self
    attr_accessor :current_test, :screenshots

    def dir_path
      Rails.root.join('tmp', '仕様書')
    end

    def file_name
      dir_path.join("#{current_test}.html")
    end

    def generate_parts(test_name, step_name)
      dir_path = Siyousho.dir_path.join(test_name)
      FileUtils.mkdir_p(dir_path)
      filename = "#{screenshots.size}.png"
      file_path = dir_path.join(filename)

      relative_file_path = test_name + '/' + filename

      Capybara.current_session.save_screenshot(file_path)
      screenshots << {image_path: relative_file_path, step: step_name}
    end

    def create_html
      return if screenshots.empty?
      html = "<html><head><title>#{current_test}</title></head><body>"

      screenshots.each do |screenshot|
        html += "<h1>#{screenshot[:step]}</h1>"
        html += "<img src='#{screenshot[:image_path]}' style='max-width: 1000px; width: auto; height: auto;'><br>" if screenshot[:image_path]
      end
      html += "</body></html>"

      File.write(file_name, html)
    end
  end
end

def modify_proc(proc)
  buffer = Parser::Source::Buffer.new('(string)')
  buffer.source = proc.source
  parser = Parser::CurrentRuby.new
  ast = parser.parse(buffer)

  rewriter = Parser::Source::TreeRewriter.new(buffer)
  ast.children.last.children.each do |child|
    rewriter.insert_before(child.location.expression, "Siyousho.generate_parts(Siyousho.current_test,'#{Unparser.unparse(child)}')\n")
  end
  modified_code = rewriter.process

  modified_modified_code = modified_code.split("\n")[1..-2].join("\n")

  Proc.new { eval(modified_modified_code) }
end

module Minitest
  class Test < Runnable
    def run
      with_info_handler do
        time_it do
          capture_exceptions do
            Siyousho.current_test = self.name
            Siyousho.screenshots = []

            SETUP_METHODS.each do |hook|
              self.send hook
            end

            proc = self.method(self.name).to_proc
            hello_block = modify_proc(proc)
            hello_block.call
          end

          TEARDOWN_METHODS.each do |hook|
            capture_exceptions do
              self.send hook
            end
            Siyousho.create_html
            Siyousho.screenshots.clear
          end
        end
      end

      Result.from self # per contract
    end
  end
end
