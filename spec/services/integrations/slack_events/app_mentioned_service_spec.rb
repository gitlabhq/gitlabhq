# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackEvents::AppMentionedService, feature_category: :integrations do
  describe '#execute' do
    let_it_be(:slack_installation) { create(:slack_integration) }
    let_it_be(:user) { create(:user) }
    let_it_be(:chat_name) do
      create(:chat_name, user: user, team_id: slack_installation.team_id, chat_id: 'U0123ABCDEF')
    end

    let(:slack_workspace_id) { slack_installation.team_id }
    let(:slack_user_id) { chat_name.chat_id }
    let(:channel_id) { 'C0123ABCDEF' }
    let(:message_ts) { '1234567890.123456' }
    let(:event_text) { "<@#{slack_installation.bot_user_id}> hello world" }

    let(:params) do
      {
        team_id: slack_workspace_id,
        event: {
          user: slack_user_id,
          channel: channel_id,
          ts: message_ts,
          text: event_text
        }
      }
    end

    let(:reactions_add_url) { "#{Slack::API::BASE_URL}/reactions.add" }
    let(:reactions_remove_url) { "#{Slack::API::BASE_URL}/reactions.remove" }
    let(:post_message_url) { "#{Slack::API::BASE_URL}/chat.postMessage" }
    let(:post_ephemeral_url) { "#{Slack::API::BASE_URL}/chat.postEphemeral" }
    let(:conversations_replies_url) { "#{Slack::API::BASE_URL}/conversations.replies" }

    subject(:execute) { described_class.new(params).execute }

    shared_examples 'does not call Slack API' do
      it 'returns success without calling the Slack API' do
        expect(Gitlab::HTTP).not_to receive(:post)
        expect(Gitlab::HTTP).not_to receive(:get)

        is_expected.to be_success
      end
    end

    context 'when event data is missing' do
      context 'when workspace id is missing' do
        let(:params) { { event: { user: slack_user_id, channel: channel_id, ts: message_ts } } }

        it { is_expected.to be_error }
      end

      context 'when user id is missing' do
        let(:params) { { team_id: slack_workspace_id, event: { channel: channel_id, ts: message_ts } } }

        it { is_expected.to be_error }
      end

      context 'when channel is missing' do
        let(:params) { { team_id: slack_workspace_id, event: { user: slack_user_id, ts: message_ts } } }

        it { is_expected.to be_error }
      end
    end

    context 'when slack installation cannot be found' do
      let(:slack_workspace_id) { 'UNKNOWN_WORKSPACE' }

      it_behaves_like 'does not call Slack API'
    end

    context 'when user is not authenticated' do
      let(:slack_user_id) { 'U_UNLINKED' }

      before do
        stub_request(:post, reactions_add_url).to_return(status: 200, body: { ok: true }.to_json,
          headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, post_ephemeral_url).to_return(status: 200, body: { ok: true }.to_json,
          headers: { 'Content-Type' => 'application/json' })
      end

      it 'adds lock reaction and posts ephemeral auth message' do
        is_expected.to be_success

        expect(WebMock).to have_requested(:post, reactions_add_url).with(
          body: hash_including('name' => 'lock', 'channel' => channel_id, 'timestamp' => message_ts)
        )
        expect(WebMock).to have_requested(:post, post_ephemeral_url).with(
          body: hash_including(
            'channel' => channel_id,
            'user' => slack_user_id,
            'text' => a_string_including('mention me again')
          )
        )
      end

      context 'when authorize URL is nil' do
        before do
          allow_next_instance_of(ChatNames::AuthorizeUserService) do |service|
            allow(service).to receive(:execute).and_return(nil)
          end
        end

        it 'does not post an ephemeral message' do
          is_expected.to be_success

          expect(WebMock).not_to have_requested(:post, post_ephemeral_url)
        end
      end

      context 'when team_domain is provided in params' do
        let(:params) do
          {
            team_id: slack_workspace_id,
            team_domain: 'my-team-domain',
            event: {
              user: slack_user_id,
              channel: channel_id,
              ts: message_ts,
              text: event_text
            }
          }
        end

        it 'uses team_domain from params in authorize_params' do
          is_expected.to be_success

          expect(WebMock).to have_requested(:post, post_ephemeral_url)
        end
      end

      context 'when ensure_user_linked raises an HTTP error' do
        before do
          allow_next_instance_of(ChatNames::AuthorizeUserService) do |service|
            allow(service).to receive(:execute).and_raise(Errno::ECONNREFUSED, 'error')
          end
        end

        it 'tracks the exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception)
            .with(instance_of(Errno::ECONNREFUSED), slack_workspace_id: slack_workspace_id)

          is_expected.to be_success
        end
      end

      context 'when reactions.add returns an error response' do
        before do
          stub_request(:post, reactions_add_url).to_return(
            status: 200,
            body: { ok: false, error: 'already_reacted' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        end

        it 'logs the Slack API error' do
          expect(Gitlab::IntegrationsLogger).to receive(:error).with(
            hash_including(message: 'Slack API error when adding reaction')
          )

          is_expected.to be_success
        end
      end

      context 'when post_ephemeral returns an error response' do
        before do
          stub_request(:post, post_ephemeral_url).to_return(
            status: 200,
            body: { ok: false, error: 'user_not_in_channel' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        end

        it 'logs the Slack API error' do
          expect(Gitlab::IntegrationsLogger).to receive(:error).with(
            hash_including(message: 'Slack API error when posting ephemeral message')
          )

          is_expected.to be_success
        end
      end

      context 'when post_ephemeral raises an HTTP error' do
        before do
          stub_request(:post, reactions_add_url).to_return(
            status: 200, body: { ok: true }.to_json, headers: { 'Content-Type' => 'application/json' })
          stub_request(:post, post_ephemeral_url).to_raise(Errno::ECONNREFUSED.new('error'))
        end

        it 'logs the error via Slack::API and does not raise' do
          expect(Gitlab::IntegrationsLogger).to receive(:error).with(
            hash_including(message: 'Slack API error when posting ephemeral message')
          )

          is_expected.to be_success
        end
      end
    end

    context 'when user is authenticated' do
      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(slack_duo_agent: false)

          stub_request(:post, reactions_add_url).to_return(status: 200, body: { ok: true }.to_json,
            headers: { 'Content-Type' => 'application/json' })
          stub_request(:post, post_ephemeral_url).to_return(status: 200, body: { ok: true }.to_json,
            headers: { 'Content-Type' => 'application/json' })
        end

        it 'adds lock reaction and posts ephemeral no-access message' do
          is_expected.to be_success

          expect(WebMock).to have_requested(:post, reactions_add_url).with(
            body: hash_including('name' => 'lock', 'channel' => channel_id, 'timestamp' => message_ts)
          )
          expect(WebMock).to have_requested(:post, post_ephemeral_url).with(
            body: hash_including(
              'channel' => channel_id,
              'user' => slack_user_id,
              'text' => a_string_including('You do not have access to this feature yet.')
            )
          )
        end
      end

      context 'when user cannot use slash commands' do
        let_it_be(:blocked_user) { create(:user, :blocked) }
        let_it_be(:blocked_chat_name) do
          create(:chat_name, user: blocked_user, team_id: slack_installation.team_id, chat_id: 'U_BLOCKED')
        end

        let(:slack_user_id) { blocked_chat_name.chat_id }

        it 'returns success without calling Slack API' do
          is_expected.to be_success

          expect(WebMock).not_to have_requested(:post, reactions_add_url)
        end
      end

      context 'when feature flag is enabled' do
        before do
          stub_feature_flags(slack_duo_agent: user)
          allow_next_instance_of(ChatNames::FindUserService) do |service|
            allow(service).to receive(:execute).and_return(chat_name)
          end
          allow(user).to receive(:allowed_to_use?).with(:duo_agent_platform).and_return(true)

          stub_request(:post, reactions_add_url).to_return(status: 200, body: { ok: true }.to_json,
            headers: { 'Content-Type' => 'application/json' })
          stub_request(:post, reactions_remove_url).to_return(status: 200, body: { ok: true }.to_json,
            headers: { 'Content-Type' => 'application/json' })
          stub_request(:post, post_message_url).to_return(status: 200, body: { ok: true }.to_json,
            headers: { 'Content-Type' => 'application/json' })
          stub_request(:post, post_ephemeral_url).to_return(status: 200, body: { ok: true }.to_json,
            headers: { 'Content-Type' => 'application/json' })
        end

        context 'when user does not have Duo Agent Platform access' do
          before do
            allow(user).to receive(:allowed_to_use?).with(:duo_agent_platform).and_return(false)
          end

          it 'adds lock reaction and posts ephemeral Duo Agent Platform message' do
            is_expected.to be_success

            expect(WebMock).to have_requested(:post, reactions_add_url).with(
              body: hash_including('name' => 'lock', 'channel' => channel_id, 'timestamp' => message_ts)
            )
            expect(WebMock).to have_requested(:post, post_ephemeral_url).with(
              body: hash_including(
                'channel' => channel_id,
                'user' => slack_user_id,
                'text' => a_string_including('This feature requires GitLab Duo Agent Platform.')
              )
            )
          end
        end

        it 'does not call the Slack users.info API' do
          is_expected.to be_success

          expect(WebMock).not_to have_requested(:get, "#{Slack::API::BASE_URL}/users.info")
        end

        it 'calls trigger_duo_flow and returns success' do
          expect_next_instance_of(described_class) do |service|
            expect(service).to receive(:trigger_duo_flow).with(user).and_call_original
          end

          is_expected.to be_success
        end
      end
    end
  end
end
