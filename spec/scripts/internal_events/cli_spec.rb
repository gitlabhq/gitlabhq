# frozen_string_literal: true

require 'spec_helper'
require 'tty/prompt/test'
require_relative '../../../scripts/internal_events/cli'

# See spec/support/shared_contexts/internal_events_cli_shared_context.rb for debugging tips
RSpec.describe Cli, feature_category: :service_ping do
  include_context 'when running the Internal Events Cli'

  let_it_be(:event1_filepath) { 'config/events/internal_events_cli_used.yml' }
  let_it_be(:event1_content) { internal_event_fixture('events/event_with_identifiers.yml') }
  let_it_be(:event2_filepath) { 'ee/config/events/internal_events_cli_opened.yml' }
  let_it_be(:event2_content) { internal_event_fixture('events/ee_event_without_identifiers.yml') }
  let_it_be(:event3_filepath) { 'config/events/internal_events_cli_closed.yml' }
  let_it_be(:event3_content) { internal_event_fixture('events/secondary_event_with_identifiers.yml') }

  shared_examples 'definition fixtures are valid' do |directory, schema_path|
    let(:schema) { ::JSONSchemer.schema(Pathname(schema_path)) }
    # The generator can return an invalid definition if the user skips the MR link
    let(:expected_errors) { a_hash_including('data_pointer' => '/introduced_by_url', 'data' => 'TODO') }

    it "for #{directory}", :aggregate_failures do
      Dir[Rails.root.join('spec', 'fixtures', 'scripts', 'internal_events', directory, '*.yml')].each do |filepath|
        attributes = YAML.safe_load(File.read(filepath))
        errors = schema.validate(attributes).to_a

        error_message = <<~TEXT
        Unexpected validation errors in: #{filepath}
        #{errors.map { |e| JSONSchemer::Errors.pretty(e) }.join("\n")}
        TEXT

        if attributes['introduced_by_url'] == 'TODO'
          expect(errors).to contain_exactly(expected_errors), error_message
        else
          expect(errors).to be_empty, error_message
        end
      end
    end
  end

  it_behaves_like 'definition fixtures are valid', 'events', 'config/events/schema.json'
  it_behaves_like 'definition fixtures are valid', 'metrics', 'config/metrics/schema/base.json'

  context 'when offline' do
    before do
      stub_product_groups(nil)
    end

    it_behaves_like 'creates the right definition files',
      'Creates a new event with product stage/section/group input manually' do
      let(:keystrokes) do
        [
          "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
          "Internal Event CLI is opened\n", # Submit description
          "internal_events_cli_opened\n", # Submit action name
          "7\n", # Select: None
          "\n", # Select: None! Continue to next section!
          "\n", # Skip MR URL
          "analytics_instrumentation\n", # Input group
          "service_ping \n", # Select product category
          "2\n", # Select [premium, ultimate]
          "y\n", # Create file
          "4\n" # Exit
        ]
      end

      let(:output_files) { [{ 'path' => event2_filepath, 'content' => event2_content }] }
    end

    it_behaves_like 'creates the right definition files',
      'Creates a new metric with product stage/section/group input manually' do
      let(:keystrokes) do
        [
          "2\n", # Enum-select: New Metric   -- calculate how often one or more existing events occur over time
          "2\n", # Enum-select: Multiple events -- count occurrences of several separate events or interactions
          'internal_events_cli', # Filters to the relevant events
          ' ', # Multi-select: internal_events_cli_closed
          "\e[B", # Arrow down to: internal_events_cli_used
          ' ', # Multi-select: internal_events_cli_used
          "\n", # Submit selections
          "\e[B", # Arrow down to: Weekly count of unique projects
          "\n", # Select: Weekly count of unique projects
          "where a defition file was created with the CLI\n", # Input description
          "2\n", # Select: Modify attributes
          "\n", # Accept group
          "\n", # Accept product categories
          "\n", # Skip URL
          "1\n", # Select: [free, premium, ultimate]
          "y\n", # Create file
          "5\n" # Exit
        ]
      end

      let(:input_files) do
        [
          { 'path' => event1_filepath, 'content' => event1_content },
          { 'path' => event3_filepath, 'content' => event3_content }
        ]
      end

      let(:output_files) do
        # rubocop:disable Layout/LineLength -- Long filepaths read better unbroken
        [{
          'path' => 'config/metrics/counts_all/count_distinct_project_id_from_internal_events_cli_closed_and_internal_events_cli_used.yml',
          'content' => 'spec/fixtures/scripts/internal_events/metrics/project_id_multiple_events.yml'
        }]
        # rubocop:enable Layout/LineLength
      end
    end
  end

  context 'when window size is unavailable' do
    before do
      # `tput <cmd>` returns empty string on error
      stub_helper(:fetch_window_size, '')
      stub_helper(:fetch_window_height, '')
    end

    it_behaves_like 'creates the right definition files',
      'Terminal size does not prevent file creation' do
      let(:keystrokes) do
        [
          "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
          "Internal Event CLI is opened\n", # Submit description
          "internal_events_cli_opened\n", # Submit action name
          "7\n", # Select: None
          "\n", # Select: None! Continue to next section!
          "\n", # Skip MR URL
          "instrumentation\n", # Filter & select group
          " \n", # Select product category
          "2\n", # Select [premium, ultimate]
          "y\n", # Create file
          "4\n" # Exit
        ]
      end

      let(:output_files) { [{ 'path' => event2_filepath, 'content' => event2_content }] }
    end
  end
end
