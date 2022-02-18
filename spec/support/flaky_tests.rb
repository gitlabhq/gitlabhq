# frozen_string_literal: true

return unless ENV['CI']
return if ENV['SKIP_FLAKY_TESTS_AUTOMATICALLY'] == "false"
return if ENV['CI_MERGE_REQUEST_LABELS'].to_s.include?('pipeline:run-flaky-tests')

require_relative '../../tooling/rspec_flaky/config'
require_relative '../../tooling/rspec_flaky/report'

RSpec.configure do |config|
  $flaky_test_example_ids = begin # rubocop:disable Style/GlobalVars
    raise "#{RspecFlaky::Config.suite_flaky_examples_report_path} doesn't exist" unless File.exist?(RspecFlaky::Config.suite_flaky_examples_report_path)

    RspecFlaky::Report.load(RspecFlaky::Config.suite_flaky_examples_report_path).map { |_, flaky_test_data| flaky_test_data.to_h[:example_id] }
  rescue => e # rubocop:disable Style/RescueStandardError
    puts e
    []
  end
  $skipped_flaky_tests_report = [] # rubocop:disable Style/GlobalVars

  config.around do |example|
    # Skip flaky tests automatically
    if $flaky_test_example_ids.include?(example.id) # rubocop:disable Style/GlobalVars
      puts "Skipping #{example.id} '#{example.full_description}' because it's flaky."
      $skipped_flaky_tests_report << example.id # rubocop:disable Style/GlobalVars
    else
      example.run
    end
  end

  config.after(:suite) do
    next unless RspecFlaky::Config.skipped_flaky_tests_report_path
    next if $skipped_flaky_tests_report.empty? # rubocop:disable Style/GlobalVars

    File.write(RspecFlaky::Config.skipped_flaky_tests_report_path, "#{ENV['CI_JOB_URL']}\n#{$skipped_flaky_tests_report.join("\n")}\n\n") # rubocop:disable Style/GlobalVars
  end
end
