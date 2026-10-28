# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Siyousho (仕様書) is a Ruby gem that generates specification documents with screenshots from Minitest system tests. For each test it takes a screenshot before every top-level statement of the test body and writes an HTML page listing the statements with their screenshots.

## Commands

### Testing
```bash
# Run the gem's unit and integration tests (default Ruby from .ruby-version)
rake test

# Run a specific test file / method
bundle exec ruby -Ilib:test test/test_instrumenter.rb
bundle exec ruby -Ilib:test test/test_instrumenter.rb -n test_single_statement_is_one_step

# Run the tests against a specific Minitest release. CI does this for the
# three latest Minitest minor releases (see gemfiles/ and the build matrix).
BUNDLE_GEMFILE=gemfiles/minitest_5.26.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/minitest_5.26.gemfile bundle exec rake test

# Run the dummy Rails app's tests against this checkout (needs Chrome).
# Installs the latest Rails and verifies that siyousho produced a document
# with screenshots for every system test and nothing for other tests.
rake integration
```

### Code Quality
```bash
rake rubocop              # lint (single-quoted strings; test/fixtures and the dummy app are excluded)
rake rubocop:autocorrect  # safe autocorrect
```

### Building & Installation
```bash
rake build          # build the gem into pkg/
rake install:local  # install it locally
```

### Default Task (runs tests and RuboCop)
```bash
rake
```

## Architecture

### Core Components (lib/siyousho/)

- **instrumenter.rb** `Siyousho::Instrumenter`: parses the source of a test method (via `method_source`) with Prism and rewrites its body so that `__siyousho_step__("<statement source>")` precedes every top-level statement. Everything between statements (comments, heredoc bodies) is kept and statements stay on their original lines, so the result can be evaluated with the original file and line. Rejects bodies with `rescue`/`ensure` and sources that cannot be read or parsed with `Siyousho::Error`.
- **recorder.rb** `Siyousho::Recorder`: one per test run. Cleans the test's previous output, takes a screenshot per step (`Siyousho.take_screenshot`, i.e. `Capybara.current_session.save_screenshot`), and writes the document on `finish` unless the test was skipped or had no steps.
- **document.rb** `Siyousho::Document`: renders the HTML (UTF-8, escaped labels, one `<section>` per step).
- **minitest.rb** `Siyousho::Minitest`: the opt-in module. `include` prepends `Run`, whose `run` replaces the test method with its instrumented body for that run (`define_singleton_method` + `instance_eval(code, file, line)`) and calls `super`, so Minitest's own setup/teardown/reporting is untouched.
- **siyousho.rb**: `Siyousho.output_root` (default `Rails.root/tmp/仕様書`, else `./tmp/仕様書`) and the Rails hook: `ActiveSupport.on_load(:action_dispatch_system_test_case) { include Siyousho::Minitest }`.

### Key Dependencies
- **prism**: parsing (supports current Ruby syntax; replaced `parser`/`unparser`)
- **method_source**: to extract a test method's source text
- **minitest** `>= 5.25, < 7`: the `run` integration relies on `Minitest::Test#run` calling `self.send(name)` inside its own hooks
- **Capybara** and **Rails**: expected in the host app, never required by the gem itself

### Output Structure
- `tmp/仕様書/<TestClass>/<test_name>.html`
- `tmp/仕様書/<TestClass>/<test_name>/0.png, 1.png, ...`
Namespaces become nested directories; unsafe filename characters are replaced with `_`.

### Tests (test/)
- `test_instrumenter.rb`, `test_document.rb`, `test_recorder.rb`: unit tests, in-process (requiring the gem no longer patches Minitest).
- `test_minitest_integration.rb`: runs `test/fixtures/suite.rb` (and other fixtures) in a child process through `test/support/fixture_runner.rb` with a fake Capybara session, then inspects the output and the generated documents. Fixtures are the gem's test inputs and are excluded from RuboCop.
- Design, perspectives and decisions: `docs/test_design.md`.

### Dummy Rails App (test/dummy_rails_app)
A deliberately minimal Rails app (no database) used only to verify the gem end to end.
- It always runs on the **latest released Rails**: the Gemfile has no version pins and `Gemfile.lock` is not committed. CI runs it on every Ruby version the gem supports.
- `test/application_system_test_case.rb` registers a `Minitest.after_run` check that fails the run if any system test did not produce a document with valid PNG screenshots, or if the non-system `PlainTest` was instrumented.
- RuboCop excludes this directory; do not add gem-style lint fixes to it.
