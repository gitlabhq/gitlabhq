# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackSlashCommands do
  it_behaves_like Integrations::BaseSlashCommands

  describe '#trigger' do
    context 'when an auth url is generated' do
      let(:project) { create(:project) }
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

  describe '#chat_responder' do
    it 'returns the responder to use for Slack' do
      expect(described_class.new.chat_responder)
        .to eq(Gitlab::Chat::Responder::Slack)
    end
  end
end
