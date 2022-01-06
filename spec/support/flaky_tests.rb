# frozen_string_literal: true

return unless ENV['CI']
return if ENV['SKIP_FLAKY_TESTS_AUTOMATICALLY'] == "false"
return if ENV['CI_MERGE_REQUEST_LABELS'].to_s.include?('pipeline:run-flaky-tests')

require_relative '../../tooling/rspec_flaky/report'

RSpec.configure do |config|
  $flaky_test_example_ids = begin # rubocop:disable Style/GlobalVars
    raise "$SUITE_FLAKY_RSPEC_REPORT_PATH is empty." if ENV['SUITE_FLAKY_RSPEC_REPORT_PATH'].to_s.empty?
    raise "#{ENV['SUITE_FLAKY_RSPEC_REPORT_PATH']} doesn't exist" unless File.exist?(ENV['SUITE_FLAKY_RSPEC_REPORT_PATH'])

    RspecFlaky::Report.load(ENV['SUITE_FLAKY_RSPEC_REPORT_PATH']).map { |_, flaky_test_data| flaky_test_data.to_h[:example_id] }
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
    next unless ENV['SKIPPED_FLAKY_TESTS_REPORT_PATH']

    File.write(ENV['SKIPPED_FLAKY_TESTS_REPORT_PATH'], "#{$skipped_flaky_tests_report.join("\n")}\n") # rubocop:disable Style/GlobalVars
  end
end
