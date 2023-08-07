# frozen_string_literal: true

return unless ENV['CI']
return if ENV['FAST_QUARANTINE'] == "false"
return if ENV['CI_MERGE_REQUEST_LABELS'].to_s.include?('pipeline:run-flaky-tests')

require_relative '../../tooling/lib/tooling/fast_quarantine'

RSpec.configure do |config|
  fast_quarantine_path = ENV.fetch(
    'RSPEC_FAST_QUARANTINE_PATH',
    File.expand_path("../../rspec/fast_quarantine-gitlab.txt", __dir__)
  )
  fast_quarantine = Tooling::FastQuarantine.new(fast_quarantine_path: fast_quarantine_path)
  skipped_examples = []

  config.around do |example|
    if fast_quarantine.skip_example?(example)
      skipped_examples << example.id
      skip "Skipping #{example.id} because it's been fast-quarantined."
    else
      example.run
    end
  end

  config.after(:suite) do
    next if skipped_examples.empty?

    skipped_tests_report_path = ENV.fetch(
      'RSPEC_SKIPPED_TESTS_REPORT_PATH',
      File.expand_path("../../rspec/flaky/skipped_tests.txt", __dir__)
    )

    next warn("#{skipped_tests_report_path} doesn't exist!") unless File.exist?(skipped_tests_report_path.to_s)

    File.write(skipped_tests_report_path, "#{ENV.fetch('CI_JOB_URL', 'local-run')}\n#{skipped_examples.join("\n")}\n\n")
  end
end
