# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::SlackBlockActions::DuoPrivacyNoticeDeclineHandler,
  feature_category: :integrations do
  describe '#execute' do
    let_it_be(:slack_installation) { create(:slack_integration) }

    let(:team_id) { slack_installation.team_id }
    let(:channel_id) { 'G0123PRIVATE' }
    let(:message_ts) { '1234567890.123456' }
    let(:response_url) { 'https://hooks.slack.com/actions/T123/456/xyz' }
    let(:reactions_add_url) { "#{Slack::API::BASE_URL}/reactions.add" }
    let(:reactions_remove_url) { "#{Slack::API::BASE_URL}/reactions.remove" }

    let(:action) do
      {
        action_id: 'duo_privacy_notice_decline',
        value: Gitlab::Json.dump(channel: channel_id, ts: message_ts)
      }
    end

    let(:params) do
      {
        team: { id: team_id },
        response_url: response_url
      }
    end

    subject(:execute) { described_class.new(params, action).execute }

    before do
      stub_request(:post, response_url).to_return(status: 200, body: 'ok')

      ok_response = {
        status: 200,
        body: { ok: true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }

      stub_request(:post, reactions_add_url).to_return(ok_response)
      stub_request(:post, reactions_remove_url).to_return(ok_response)
    end

    it 'replaces the notice with the cancelled message via the response_url' do
      execute

      expect(WebMock).to have_requested(:post, response_url).with(
        body: hash_including(
          'replace_original' => true,
          'text' => s_('SlackIntegration|Okay, GitLab Duo will not process this mention. ' \
            'Mention GitLab Duo again if you change your mind.')
        )
      )
    end

    it 'swaps the lock reaction for an x reaction on the original mention' do
      execute

      expect(WebMock).to have_requested(:post, reactions_remove_url).with(
        body: hash_including('name' => 'lock', 'channel' => channel_id, 'timestamp' => message_ts)
      )
      expect(WebMock).to have_requested(:post, reactions_add_url).with(
        body: hash_including('name' => 'x', 'channel' => channel_id, 'timestamp' => message_ts)
      )
    end

    it 'does not re-enqueue the original mention' do
      expect(Integrations::SlackEventWorker).not_to receive(:perform_async)

      execute
    end

    context 'when the button value is not valid JSON' do
      let(:action) { { value: 'not-json' } }

      it 'still replaces the notice but does not touch reactions' do
        execute

        expect(WebMock).to have_requested(:post, response_url)
        expect(WebMock).not_to have_requested(:post, reactions_remove_url)
        expect(WebMock).not_to have_requested(:post, reactions_add_url)
      end
    end

    context 'when the slack installation cannot be found' do
      let(:params) do
        {
          team: { id: 'T_UNKNOWN' },
          response_url: response_url
        }
      end

      it 'still replaces the notice but does not touch reactions' do
        execute

        expect(WebMock).to have_requested(:post, response_url)
        expect(WebMock).not_to have_requested(:post, reactions_remove_url)
      end
    end

    context 'when response_url is missing' do
      let(:params) { { team: { id: team_id } } }

      it 'does not post to the response_url' do
        execute

        expect(WebMock).not_to have_requested(:post, response_url)
      end
    end

    context 'when the response_url request fails' do
      before do
        stub_request(:post, response_url).to_raise(Errno::ECONNREFUSED.new('error'))
      end

      it 'tracks the exception and does not raise' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(Errno::ECONNREFUSED), slack_workspace_id: team_id)

        expect { execute }.not_to raise_error
      end
    end
  end
end
