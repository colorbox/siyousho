## [Unreleased]

### Changed (breaking)

- Instrumentation is opt-in: `include Siyousho::Minitest` into a test class. Rails system tests (`ActionDispatch::SystemTestCase`) are instrumented automatically; other tests in the same process are no longer touched (previously every Minitest test was, which broke any test without a Capybara session)
- Documents are written to `tmp/仕様書/<TestClass>/<test_name>.html` with screenshots in `tmp/仕様書/<TestClass>/<test_name>/`; the output of a previous run of the same test is removed first
- Step labels are the statement's source text as written (previously normalized by Unparser); the document declares UTF-8, escapes labels and keeps multi-line labels
- Skipped tests produce no document
- Failure and error locations point into the test file instead of an `eval`
- `Siyousho.output_root` configures the output directory
- Require Ruby 3.3 or later (Ruby 3.0, 3.1 and 3.2 are no longer supported)

### Fixed

- Tests with a single statement or an empty body no longer raise
- Statements containing single quotes no longer break the instrumented code
- Heredocs in a test body are handled
- `require 'siyousho'` no longer depends on Minitest having been loaded first
- Fix the `Minitest::Test#run` override for Minitest 5.25+, which removed the instance-level `with_info_handler`

### Dependencies

- Parse with Prism; `parser` and `unparser` are no longer dependencies
- Declare `minitest >= 5.25, < 7` and `method_source >= 1.0`
- CI: test on Ruby 3.3, 3.4 and 4.0 against Minitest 5.26, 5.27 and 6.0; run on pushes to `main`

## [0.1.0] - 2023-09-24

- Initial release
