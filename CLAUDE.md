# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Siyousho (仕様書) is a Ruby gem that automatically generates specification documents with screenshots during E2E testing. It works by intercepting test execution and injecting screenshot capture code using Ruby AST manipulation.

## Commands

### Testing
```bash
# Run the gem's unit tests
rake test

# Run a specific test file
ruby -Ilib:test test/test_siyousho.rb

# Run a specific test method
ruby -Ilib:test test/test_siyousho.rb -n test_that_it_has_a_version_number

# Run the dummy Rails app's system tests against this checkout (needs Chrome).
# This installs the latest Rails and verifies that siyousho produced a document
# with screenshots for every system test.
rake integration
```

### Code Quality
```bash
# Run RuboCop linter
rake rubocop

# Auto-fix RuboCop issues
rake rubocop:autocorrect
```

### Building & Installation
```bash
# Build the gem
rake build

# Install locally for testing
rake install:local
```

### Default Task (runs tests and RuboCop)
```bash
rake
```

## Architecture

### Core Components

1. **Siyousho Module** (lib/siyousho.rb): Main module that:
   - Manages screenshot capture during test execution
   - Generates HTML documentation with embedded screenshots
   - Monkey patches Minitest::Test to intercept test execution
   - Uses AST manipulation to inject screenshot calls into test methods

2. **AST Manipulation**: The gem uses `parser` and `unparser` to:
   - Parse test method source code into AST
   - Inject `Siyousho.generate_parts` calls before each statement
   - Reconstruct and execute the modified code

### Key Dependencies
- **parser/unparser**: For Ruby code manipulation
- **method_source**: To extract test method source
- **Capybara**: For screenshot capture (expected in host app)
- **Rails**: For path helpers (expected in host app)

### Output Structure
Screenshots and HTML are saved to:
- `Rails.root/tmp/仕様書/[test_name]/[0,1,2...].png` - Screenshots
- `Rails.root/tmp/仕様書/[test_name].html` - HTML documentation

### Integration Points
The gem hooks into Minitest's test execution flow by overriding the `run` method in `Minitest::Test`. It captures screenshots before each statement in the test method and generates an HTML report after teardown.

### Dummy Rails App (test/dummy_rails_app)
A deliberately minimal Rails app (no database, two controllers, one system test file) used only to verify the gem end to end.
- It always runs on the **latest released Rails**: the Gemfile has no version pins and `Gemfile.lock` is not committed. CI runs it on every Ruby version the gem supports (the same matrix as the gem's own job).
- `test/application_system_test_case.rb` registers a `Minitest.after_run` check that fails the run if any system test did not produce an HTML document with valid PNG screenshots.
- RuboCop excludes this directory; do not add gem-style lint fixes to it.
- Each system test must contain at least two statements (the AST injection assumes a multi-statement body) and must not contain single quotes in its source (the injected step name is a single-quoted string).
