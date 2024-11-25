# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackSlashCommands, feature_category: :integrations do
  it_behaves_like Integrations::Base::SlashCommands

  describe '#trigger' do
    context 'when an auth url is generated' do
      let_it_be(:project) { create(:project) }
      let(:params) do
        {
          team_domain: 'http://domain.tld',
          team_id: 'T3423423',
          user_id: 'U234234',
          user_name: 'mepmep',
          token: 'token'
        }
      end

      let(:integration) do
        project.create_slack_slash_commands_integration(
          properties: { token: 'token' },
          active: true
        )
      end

      let(:authorize_url) do
        'http://authorize.example.com/'
      end

      before do
        allow(integration).to receive(:authorize_chat_name_url).and_return(authorize_url)
      end

      it 'uses slack compatible links' do
        response = integration.trigger(params)

        expect(response[:text]).to include("<#{authorize_url}|connect your GitLab account>")
      end
    end
  end

  describe '#redirect_url' do
    let(:integration) { build(:slack_slash_commands_integration) }

    subject { integration.redirect_url('team', 'channel', 'www.example.com') }

    it { is_expected.to eq('slack://channel?team=team&id=channel') }
  end

  describe '#confirmation_url' do
    let(:integration) { build(:slack_slash_commands_integration) }
    let(:params) do
      {
        team_id: 'T123456',
        channel_id: 'C654321',
        response_url: 'https://hooks.slack.com/services/T123456/C654321'
      }
    end

    subject { integration.confirmation_url('command-id', params) }

    it { is_expected.to be_present }
  end
end
