# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::SlackBlockActions::DuoPrivacyNoticeHandler,
  feature_category: :integrations do
  describe '#execute' do
    let_it_be(:slack_installation) { create(:slack_integration) }
    let(:reactions_remove_url) { "#{Slack::API::BASE_URL}/reactions.remove" }
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:chat_name) do
      create(:chat_name, user: user, team_id: slack_installation.team_id, chat_id: 'U0123ABCDEF')
    end

    let(:team_id) { slack_installation.team_id }
    let(:user_id) { chat_name.chat_id }
    let(:channel_id) { 'G0123PRIVATE' }
    let(:message_ts) { '1234567890.123456' }
    let(:thread_ts) { '1234567890.111111' }
    let(:response_url) { 'https://hooks.slack.com/actions/T123/456/xyz' }

    let(:action) do
      {
        action_id: 'duo_privacy_notice_acknowledge',
        value: Gitlab::Json.dump(channel: channel_id, ts: message_ts, thread_ts: thread_ts)
      }
    end

    let(:params) do
      {
        team: { id: team_id },
        user: { id: user_id },
        response_url: response_url
      }
    end

    subject(:execute) { described_class.new(params, action).execute }

    before do
      stub_request(:post, response_url).to_return(status: 200, body: 'ok')
      stub_request(:post, reactions_remove_url).to_return(
        status: 200,
        body: { ok: true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    it 'persists the acknowledgement on the chat name' do
      expect { execute }.to change { chat_name.reload.duo_privacy_notice_acknowledged_at }.from(nil)
    end

    it 'removes the lock reaction from the original mention' do
      execute

      expect(WebMock).to have_requested(:post, reactions_remove_url).with(
        body: hash_including('name' => 'lock', 'channel' => channel_id, 'timestamp' => message_ts)
      )
    end

    it 're-enqueues the original mention for processing' do
      expect(Integrations::SlackEventWorker).to receive(:perform_async).with(
        slack_event: 'app_mention',
        params: hash_including(
          team_id: team_id,
          event_id: "duo-privacy-ack-#{team_id}-#{channel_id}-#{message_ts}",
          event: hash_including(
            type: 'app_mention',
            user: user_id,
            channel: channel_id,
            ts: message_ts,
            thread_ts: thread_ts
          )
        )
      )

      execute
    end

    it 'replaces the notice message via the response_url' do
      execute

      expect(WebMock).to have_requested(:post, response_url).with(
        body: hash_including('replace_original' => true)
      )
    end

    context 'when the chat name cannot be found' do
      let(:user_id) { 'U_UNKNOWN' }

      it 'does nothing' do
        expect(Integrations::SlackEventWorker).not_to receive(:perform_async)

        execute

        expect(WebMock).not_to have_requested(:post, response_url)
      end
    end

    context 'when team or user is missing from the payload' do
      let(:params) { { response_url: response_url } }

      it 'does nothing' do
        expect(Integrations::SlackEventWorker).not_to receive(:perform_async)

        execute

        expect(chat_name.reload.duo_privacy_notice_acknowledged_at).to be_nil
      end
    end

    context 'when the button value is not valid JSON' do
      let(:action) { { value: 'not-json' } }

      it 'persists the acknowledgement but does not re-enqueue the mention' do
        expect(Integrations::SlackEventWorker).not_to receive(:perform_async)

        expect { execute }.to change { chat_name.reload.duo_privacy_notice_acknowledged_at }.from(nil)

        expect(WebMock).not_to have_requested(:post, reactions_remove_url)
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

    context 'when response_url is missing' do
      let(:params) do
        {
          team: { id: team_id },
          user: { id: user_id }
        }
      end

      it 'still persists the acknowledgement' do
        expect { execute }.to change { chat_name.reload.duo_privacy_notice_acknowledged_at }.from(nil)
      end
    end
  end
end
