# frozen_string_literal: true

require_relative 'siyousho/version'

module Siyousho
  def self.save_path
    Rails.root.join('tmp', '仕様書')
  end
end

class RSpec::Core::Example
  def screenshots
    @screenshots ||= []
  end
end

module Turnip
  module Execute
    alias_method :original_step, :step

    def step(step_or_description, *extra_args)
      original_step(step_or_description, *extra_args)

      unless step_or_description.class == String
        dir_path = Siyousho.save_path.join(::RSpec.current_example.file_path)
        FileUtils.mkdir_p(dir_path)
        filename = "#{step_or_description.raw[:id]}.png"
        file_path = dir_path.join(filename)

        relative_file_path = ::RSpec.current_example.file_path + '/' + filename

        # ステップ実行後のスクリーンショット
        save_screenshot(file_path)
        screenshots << {image_path: relative_file_path, step: step_or_description.raw[:text]}
      else
        screenshots << {step: step_or_description}
      end
    end

    def screenshots
      ::RSpec.current_example.screenshots
    end

    def save_screenshot(filename)
      path = File.join(Siyousho.save_path, filename)
      Capybara.current_session.save_screenshot(path)
    end

  end
end

RSpec.configure do |config|
  config.after(:each) do |example|
    TurnipReport.generate_html
  end
end

module TurnipReport
  def self.generate_html
    html = "<html><head><title>#{::RSpec.current_example.metadata[:example_group][:full_description]}</title></head><body>"
    RSpec.current_example.screenshots.each do |screenshot|
      html += "<h1>#{screenshot[:step]}</h1>"
      html += "<img src='#{screenshot[:image_path]}' style='max-width: 1000px; width: auto; height: auto;'><br>" if screenshot[:image_path]
    end
    html += "</body></html>"

    dir_path = Siyousho.save_path
    file_name = "#{::RSpec.current_example.metadata[:example_group][:full_description]}.html"
    file_path = dir_path.join(file_name)

    File.write(file_path, html)
  end
end
