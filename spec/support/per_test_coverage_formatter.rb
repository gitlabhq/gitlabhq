# frozen_string_literal: true

# RSpec formatter that writes per-test, per-source-file, per-line coverage
# data in the format consumed by the `gitlab_quality-test_tooling` gem's
# `--per-test-coverage` flag.
#
# Activation lives in spec/support/rspec.rb and requires both `ENV['CI']`
# and `ENV['GLCI_PER_TEST_COVERAGE'] == 'true'`. With either unset, the
# formatter does not attach and `Coverage.start` is not deferred.
#
# Capture strategy: defer `Coverage.start` to `before(:suite)` so only
# files autoloaded during examples get instrumented, then call
# `Coverage.result(stop: false, clear: true)` after each example to read
# (and reset) the delta for that example. Each example's data is streamed
# to disk as a single NDJSON line, which bounds memory to one example's
# worth of data regardless of suite size.

require 'coverage'
require 'fileutils'
require 'rspec/core/formatters/base_formatter'
require 'securerandom'

module Support
  class PerTestCoverageFormatter < RSpec::Core::Formatters::BaseFormatter
    RSpec::Core::Formatters.register self, :example_finished, :stop

    PROJECT_DIR_PREFIX_RE = %r{\A#{Regexp.escape(ENV.fetch('CI_PROJECT_DIR', '/builds/gitlab-org/gitlab'))}/}

    def initialize(output)
      super
      @file = nil
    end

    def example_finished(notification)
      delta = Coverage.result(stop: false, clear: true)
      per_file = extract_per_file(delta)
      return if per_file.empty?

      ensure_file_open
      @file.puts(Gitlab::Json.generate(id: notification.example.id, files: per_file))
    end

    def stop(_notification)
      @file&.close
      @file = nil
    end

    private

    def ensure_file_open
      return if @file

      path = "tmp/per-test-coverage-rspec-#{ENV.fetch('CI_JOB_NAME_SLUG', 'local')}-#{SecureRandom.hex(6)}.ndjson"
      FileUtils.mkdir_p(File.dirname(path))
      @file = File.open(path, 'w')
    end

    # `Coverage.result` returns `{lines: [...], branches: {...}}` per file in
    # default mode and a bare array in plain line mode. Filter to repo files
    # with at least one positive line hit, strip the project-dir prefix,
    # keep only the line-hit array.
    def extract_per_file(raw)
      raw.each_with_object({}) do |(path, data), out|
        next unless PROJECT_DIR_PREFIX_RE.match?(path)

        lines = data.is_a?(Hash) ? data[:lines] : data
        next unless lines.is_a?(Array)
        next unless lines.any? { |v| v && v.positive? }

        out[path.sub(PROJECT_DIR_PREFIX_RE, '')] = lines
      end
    end
  end
end
