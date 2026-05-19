# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackSlashCommands, feature_category: :integrations do
  let_it_be(:integration) { create(:slack_slash_commands_integration) }

  describe '.title' do
    subject { integration.title }

    it { is_expected.to eq('Slack slash commands') }
  end

  describe '.description' do
    subject { integration.description }

    it { is_expected.to be_a String }
  end

  describe '.to_param' do
    subject { integration.to_param }

    it { is_expected.to eq('slack_slash_commands') }
  end
end
