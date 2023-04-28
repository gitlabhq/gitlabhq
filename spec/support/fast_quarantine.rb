# frozen_string_literal: true

return unless ENV['CI']
return if ENV['FAST_QUARANTINE'] == "false"
return if ENV['CI_MERGE_REQUEST_LABELS'].to_s.include?('pipeline:run-flaky-tests')

require_relative '../../tooling/rspec_flaky/config'

# rubocop:disable Style/GlobalVars
RSpec.configure do |config|
  $fast_quarantined_entity_identifiers = begin
    raise "#{ENV['RSPEC_FAST_QUARANTINE_PATH']} doesn't exist" unless File.exist?(ENV['RSPEC_FAST_QUARANTINE_PATH'])

    quarantined_entity_identifiers = File.read(ENV['RSPEC_FAST_QUARANTINE_PATH']).lines
    quarantined_entity_identifiers.compact!
    quarantined_entity_identifiers.map! do |quarantined_entity_identifier|
      quarantined_entity_identifier.delete_prefix('./').strip
    end
  rescue => e # rubocop:disable Style/RescueStandardError
    puts e
    []
  end
  $skipped_tests = []

  config.around do |example|
    fast_quarantined_entity_identifier = $fast_quarantined_entity_identifiers.find do |quarantined_entity_identifier|
      case quarantined_entity_identifier
      when /^.+_spec\.rb\[[\d:]+\]$/ # example id, e.g. spec/tasks/gitlab/usage_data_rake_spec.rb[1:5:2:1]
        example.id == "./#{quarantined_entity_identifier}"
      else # whole file, e.g. ee/spec/features/boards/swimlanes/epics_swimlanes_sidebar_spec.rb
        example.metadata[:rerun_file_path] == "./#{quarantined_entity_identifier}"
      end
    end

    if fast_quarantined_entity_identifier
      puts "Skipping #{example.id} '#{example.full_description}' because it's been fast-quarantined with '#{fast_quarantined_entity_identifier}'."
      $skipped_tests << example.id
    else
      example.run
    end
  end

  config.after(:suite) do
    next unless RspecFlaky::Config.skipped_flaky_tests_report_path
    next if $skipped_tests.empty?

    File.write(RspecFlaky::Config.skipped_flaky_tests_report_path, "#{ENV['CI_JOB_URL']}\n#{$skipped_tests.join("\n")}\n\n")
  end
end
# rubocop:enable Style/GlobalVars
