# Siyousho

Automatically generates specification documents (仕様書) with screenshots from your end-to-end tests.

For every test, Siyousho takes a screenshot before each statement of the test body and writes an HTML page that lists the statements next to their screenshots.

## Installation

Add the gem to the `test` group of your application's Gemfile:

```ruby
gem 'siyousho', group: :test
```

## Usage

### Rails

Require the gem from `test/test_helper.rb`:

```ruby
require 'siyousho'
```

Every system test (`ActionDispatch::SystemTestCase`) is instrumented automatically; other kinds of tests are left alone. Run your system tests as usual:

```
bin/rails test:system
```

Documents are written to `tmp/仕様書/<TestClass>/<test_name>.html`, with the screenshots in `tmp/仕様書/<TestClass>/<test_name>/`.

### Other Minitest + Capybara tests

Include `Siyousho::Minitest` into any test class whose tests drive a Capybara session:

```ruby
class CheckoutTest < Minitest::Test
  include Siyousho::Minitest

  def test_checkout
    visit '/cart'
    click_on 'Checkout'
    assert_text 'Thank you'
  end
end
```

### Configuration

```ruby
Siyousho.output_root = Rails.root.join('doc', 'specs') # default: Rails.root/tmp/仕様書
```

### Notes

- Each top-level statement of the test body is one step; statements inside blocks (`within ... do`) belong to the enclosing step. The label is the statement's source text.
- A failing test still produces a document with the steps up to the failure. Skipped tests produce no document.
- Test bodies with `rescue`/`ensure` clauses are not supported.
- Requires Ruby 3.3+ and Minitest 5.25 to 6.x.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests and `rake integration` to run the dummy Rails app's tests against your checkout (needs Chrome). You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/colorbox/siyousho. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/colorbox/siyousho/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Siyousho project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/colorbox/siyousho/blob/main/CODE_OF_CONDUCT.md).
