# frozen_string_literal: true

require 'erb'

module Siyousho
  # One recorded step: the statement's source text and the screenshot path
  # relative to the document.
  Step = Struct.new(:label, :image, keyword_init: true)

  # Renders the HTML document of one test.
  class Document
    STYLE = <<~CSS
      body { font-family: sans-serif; margin: 2rem; }
      h2 code { white-space: pre-wrap; }
      img { max-width: 1000px; width: auto; height: auto; border: 1px solid #ccc; }
    CSS

    def initialize(title:, steps:)
      @title = title
      @steps = steps
    end

    def to_html
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>#{h(@title)}</title>
        <style>
        #{STYLE.chomp}
        </style>
        </head>
        <body>
        <h1>#{h(@title)}</h1>
        #{@steps.each_with_index.map { |step, index| section(step, index) }.join("\n")}
        </body>
        </html>
      HTML
    end

    private

    def section(step, index)
      html = "<section>\n<h2><code>#{h(step.label)}</code></h2>\n"
      html << %(<img src="#{h(step.image)}" alt="step #{index + 1}">\n) if step.image
      html << '</section>'
    end

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end
  end
end
