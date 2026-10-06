# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackEvents::AgentDmService, feature_category: :integrations do
  describe '#execute' do
    let_it_be(:slack_installation) { create(:slack_integration) }
    let_it_be(:user) { create(:user) }
    let_it_be(:chat_name) do
      create(:chat_name, user: user, team_id: slack_installation.team_id, chat_id: 'U0123ABCDEF')
    end

    let(:slack_workspace_id) { slack_installation.team_id }
    let(:slack_user_id) { chat_name.chat_id }
    let(:channel_id) { 'D0123ABCDEF' }
    let(:message_ts) { '1234567890.123456' }
    let(:event) do
      {
        user: slack_user_id,
        channel: channel_id,
        channel_type: 'im',
        ts: message_ts,
        text: 'hello agent'
      }
    end

    let(:params) do
      {
        team_id: slack_workspace_id,
        event: event
      }
    end

    subject(:execute) { described_class.new(params).execute }

    shared_examples 'does not process the message' do
      it 'returns success without calling the Slack API' do
        expect(Gitlab::HTTP).not_to receive(:post)
        expect(Gitlab::HTTP).not_to receive(:get)

        is_expected.to be_success
      end
    end

    context 'when the message was authored by a bot' do
      let(:event) { super().merge(bot_id: 'B0123ABCDEF') }

      it_behaves_like 'does not process the message'
    end

    context 'when the message has a subtype' do
      let(:event) { super().merge(subtype: 'message_changed') }

      it_behaves_like 'does not process the message'
    end

    context 'when a group DM message mentions the bot' do
      let(:event) { super().merge(channel_type: 'mpim', text: "<@#{slack_installation.bot_user_id}> hello") }

      it_behaves_like 'does not process the message'
    end

    context 'when a group DM message comes from a workspace without a bot installation' do
      let(:slack_workspace_id) { 'T_UNKNOWN' }
      let(:event) { super().merge(channel_type: 'mpim') }

      it_behaves_like 'does not process the message'
    end

    context 'when the message is a fresh user message' do
      let(:reactions_add_url) { "#{Slack::API::BASE_URL}/reactions.add" }
      let(:post_ephemeral_url) { "#{Slack::API::BASE_URL}/chat.postEphemeral" }

      before do
        stub_request(:post, reactions_add_url).to_return(status: 200, body: { ok: true }.to_json,
          headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, post_ephemeral_url).to_return(status: 200, body: { ok: true }.to_json,
          headers: { 'Content-Type' => 'application/json' })
        stub_feature_flags(slack_duo_agent: false)
      end

      it 'delegates to the mention pipeline' do
        is_expected.to be_success

        expect(WebMock).to have_requested(:post, reactions_add_url).with(
          body: hash_including('name' => 'lock', 'channel' => channel_id, 'timestamp' => message_ts)
        )
      end

      context 'when a 1:1 DM message mentions the bot' do
        let(:event) { super().merge(text: "<@#{slack_installation.bot_user_id}> hello") }

        it 'does not skip the message' do
          is_expected.to be_success

          expect(WebMock).to have_requested(:post, reactions_add_url)
        end
      end

      context 'when a group DM message does not mention the bot' do
        let(:event) { super().merge(channel_type: 'mpim') }

        it 'does not skip the message' do
          is_expected.to be_success

          expect(WebMock).to have_requested(:post, reactions_add_url)
        end
      end
    end
  end
end
