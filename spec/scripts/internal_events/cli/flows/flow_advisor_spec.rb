# frozen_string_literal: true

require 'spec_helper'
require 'tty/prompt/test'
require_relative '../../../../../scripts/internal_events/cli'

RSpec.describe 'InternalEventsCli::Flows::FlowAdvisor', :aggregate_failures, feature_category: :service_ping do
  include_context 'when running the Internal Events Cli'

  it "handles when user isn't trying to track product usage" do
    queue_cli_inputs([
      "4\n", # Enum-select: ...am I in the right place?
      "n\n" # No --> Are you trying to track customer usage of a GitLab feature?
    ])

    with_cli_thread do
      expect { plain_last_lines(50) }.to eventually_include_cli_text("Oh no! This probably isn't the tool you need!")
    end
  end

  it "handles when product usage can't be tracked with events" do
    queue_cli_inputs([
      "4\n", # Enum-select: ...am I in the right place?
      "y\n", # Yes --> Are you trying to track customer usage of a GitLab feature?
      "n\n" # No --> Can usage for the feature be measured by tracking a specific user action?
    ])

    with_cli_thread do
      expect { plain_last_lines(50) }.to eventually_include_cli_text("Oh no! This probably isn't the tool you need!")
    end
  end

  it 'handles when user needs to add a new event' do
    queue_cli_inputs([
      "4\n", # Enum-select: ...am I in the right place?
      "y\n", # Yes --> Are you trying to track customer usage of a GitLab feature?
      "y\n", # Yes --> Can usage for the feature be measured by tracking a specific user action?
      "n\n", # No --> Is the event already tracked?
      "n\n" # No --> Ready to start?
    ])

    with_cli_thread do
      expect { plain_last_lines(30) }
        .to eventually_include_cli_text("Okay! The next step is adding a new event! (~5-10 min)")
    end
  end

  it 'handles when user needs to add a new metric' do
    queue_cli_inputs([
      "4\n", # Enum-select: ...am I in the right place?
      "y\n", # Yes --> Are you trying to track customer usage of a GitLab feature?
      "y\n", # Yes --> Can usage for the feature be measured by tracking a specific user action?
      "y\n", # Yes --> Is the event already tracked?
      "n\n" # No --> Ready to start?
    ])

    with_cli_thread do
      expect { plain_last_lines(30) }
        .to eventually_include_cli_text("Amazing! The next step is adding a new metric! (~8-15 min)")
    end
  end
end
