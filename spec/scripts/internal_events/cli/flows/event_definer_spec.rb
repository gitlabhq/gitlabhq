# frozen_string_literal: true

require 'spec_helper'
require 'tty/prompt/test'
require_relative '../../../../../scripts/internal_events/cli'

RSpec.describe 'InternalEventsCli::Flows::EventDefiner', :aggregate_failures, feature_category: :service_ping do
  include_context 'when running the Internal Events Cli'

  describe 'end-to-end behavior' do
    YAML.safe_load(File.read('spec/fixtures/scripts/internal_events/event_definer_examples.yml')).each do |test_case|
      it_behaves_like 'creates the right definition files', test_case['description'], test_case
    end
  end

  context 'with invalid event name' do
    it 'prompts user to select another name' do
      queue_cli_inputs([
        "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
        "Engineer uses Internal Event CLI to define a new event\n", # Submit description
        "badDDD_ event (name) with // prob.lems\n" # Submit action name
      ])

      with_cli_thread do
        expect { prompt.output.string }.to eventually_include_cli_text('Invalid event name.')
      end
    end
  end

  context 'with a valid event name' do
    it 'continues to the next step' do
      queue_cli_inputs([
        "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
        "Engineer uses Internal Event CLI to define a new event\n", # Submit description
        "a_totally_fine_0123456789_name\n" # Submit action name
      ])

      with_cli_thread do
        expect { prompt.output.string }.to eventually_include_cli_text('Step 3 / 8')
      end
    end
  end
end
