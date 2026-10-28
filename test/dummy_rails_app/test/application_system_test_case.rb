require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # siyousho instruments ActionDispatch::SystemTestCase automatically.
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  COMPLETED = []

  def after_teardown
    super
  ensure
    COMPLETED << [self.class.name, name]
  end
end

# After the run, check that siyousho wrote a document with real screenshots for
# every system test that ran, and nothing for tests that are not system tests.
# This makes `bin/rails test:all` double as the integration check for the gem:
# the process exits non-zero if anything is missing.
Minitest.after_run do
  dir = Rails.root.join("tmp", "仕様書")
  png_magic = "\x89PNG\r\n\x1a\n".b

  problems = ApplicationSystemTestCase::COMPLETED.filter_map do |test_class, test_name|
    html = dir.join(*test_class.split("::"), "#{test_name}.html")
    next "#{html}: not generated" unless html.exist?

    images = File.read(html).scan(/<img src="([^"]+)"/).flatten
    next "#{html}: contains no screenshots" if images.empty?

    broken = images.reject do |image|
      path = html.dirname.join(image)
      path.exist? && File.binread(path, png_magic.bytesize) == png_magic
    end
    "#{html}: invalid screenshots #{broken.join(', ')}" if broken.any?
  end
  problems << "#{dir.join('PlainTest')}: a non-system test was instrumented" if dir.join("PlainTest").exist?

  if problems.empty?
    puts "siyousho: generated #{ApplicationSystemTestCase::COMPLETED.size} document(s) in #{dir}"
  else
    abort "siyousho output check failed:\n  #{problems.join("\n  ")}"
  end
end
