# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Slack::API, feature_category: :integrations do
  describe '#post' do
    let(:slack_installation) { build(:slack_integration) }
    let(:api_method) { 'api_method_call' }
    let(:api_url) { "#{described_class::BASE_URL}/#{api_method}" }
    let(:payload) { { foo: 'bar' } }

    subject(:post) { described_class.new(slack_installation).post(api_method, payload) }

    before do
      stub_request(:post, api_url).to_return(
        status: 200, body: { ok: true }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    it 'posts to the Slack API correctly' do
      post

      expect(WebMock).to have_requested(:post, api_url).with(
        body: payload.to_json,
        headers: {
          'Authorization' => "Bearer #{slack_installation.bot_access_token}",
          'Content-Type' => 'application/json; charset=utf-8'
        })
    end

    it 'returns a hash response' do
      is_expected.to be_a(Hash)
    end

    context 'when the response is not a hash' do
      before do
        stub_request(:post, api_url).to_return(
          status: 200, body: 'unexpected string',
          headers: { 'Content-Type' => 'text/plain' }
        )
      end

      it 'returns a failure hash' do
        expect(post).to eq({ 'ok' => false, 'error' => 'unexpected string' })
      end
    end

    context 'when an HTTP error is raised' do
      before do
        stub_request(:post, api_url).to_raise(SocketError.new('connection failed'))
      end

      it 'raises the error' do
        expect { post }.to raise_error(SocketError, 'connection failed')
      end
    end

    context 'when the slack installation has no bot token' do
      let(:slack_installation) { build(:slack_integration, :legacy) }

      it 'raises an error' do
        expect { post }.to raise_error(ArgumentError)
      end
    end
  end

  shared_examples 'a Slack API method' do
    let(:slack_installation) { build(:slack_integration) }
    let(:api) { described_class.new(slack_installation) }
    let(:api_url) { "#{described_class::BASE_URL}/#{action}" }

    before do
      stub_request(:post, api_url).to_return(
        status: 200, body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    it 'makes the correct API call' do
      subject

      expect(WebMock).to have_requested(:post, api_url)
        .with(body: hash_including(payload.deep_stringify_keys))
    end

    it 'logs the action' do
      expect(Gitlab::IntegrationsLogger).to receive(:info)
        .with(hash_including(expected_log_payload))

      subject
    end

    context 'when the request succeeds' do
      let(:response_body) { { ok: true } }

      it 'does not log an error' do
        expect(Gitlab::IntegrationsLogger).not_to receive(:error)

        subject
      end
    end

    context 'when the Slack API returns an error' do
      let(:response_body) { { ok: false, error: 'error' } }

      it 'logs the error' do
        expect(Gitlab::IntegrationsLogger).to receive(:error)
          .with(hash_including(message: expected_error_message))

        subject
      end
    end
  end

  describe '#add_reaction' do
    it_behaves_like 'a Slack API method' do
      let(:action) { 'reactions.add' }
      let(:response_body) { { ok: true } }
      let(:payload) { { channel: 'C123', name: 'eyes', timestamp: '123.456' } }
      let(:expected_log_payload) do
        { message: 'Slack API: adding reaction', reaction: 'eyes', timestamp: '123.456' }
      end

      let(:expected_error_message) { 'Slack API error when adding reaction' }

      subject { api.add_reaction(**payload) }
    end
  end

  describe '#remove_reaction' do
    it_behaves_like 'a Slack API method' do
      let(:action) { 'reactions.remove' }
      let(:response_body) { { ok: true } }
      let(:payload) { { channel: 'C123', name: 'eyes', timestamp: '123.456' } }
      let(:expected_log_payload) do
        { message: 'Slack API: removing reaction', reaction: 'eyes', timestamp: '123.456' }
      end

      let(:expected_error_message) { 'Slack API error when removing reaction' }

      subject { api.remove_reaction(**payload) }
    end
  end

  describe '#post_ephemeral' do
    it_behaves_like 'a Slack API method' do
      let(:action) { 'chat.postEphemeral' }
      let(:response_body) { { ok: true } }
      let(:payload) { { channel: 'C123', user: 'U456', text: 'hello' } }
      let(:expected_log_payload) { { message: 'Slack API: posting ephemeral', channel_id: 'C123' } }
      let(:expected_error_message) { 'Slack API error when posting ephemeral message' }

      subject { api.post_ephemeral(**payload) }
    end

    context 'with thread_ts' do
      let(:slack_installation) { build(:slack_integration) }
      let(:api) { described_class.new(slack_installation) }
      let(:api_url) { "#{described_class::BASE_URL}/chat.postEphemeral" }

      before do
        stub_request(:post, api_url).to_return(
          status: 200, body: { ok: true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'includes thread_ts in the payload when provided' do
        api.post_ephemeral(channel: 'C123', user: 'U456', text: 'hello', thread_ts: '123.456')

        expect(WebMock).to have_requested(:post, api_url)
          .with(body: hash_including('thread_ts' => '123.456'))
      end

      it 'omits thread_ts from the payload when not provided' do
        api.post_ephemeral(channel: 'C123', user: 'U456', text: 'hello')

        expect(WebMock).to have_requested(:post, api_url)
          .with { |req| req.body.exclude?('thread_ts') }
      end

      it 'omits thread_ts from the payload when nil' do
        api.post_ephemeral(channel: 'C123', user: 'U456', text: 'hello', thread_ts: nil)

        expect(WebMock).to have_requested(:post, api_url)
          .with { |req| req.body.exclude?('thread_ts') }
      end
    end
  end

  describe '#post_message' do
    it_behaves_like 'a Slack API method' do
      let(:action) { 'chat.postMessage' }
      let(:response_body) { { ok: true } }
      let(:payload) { { channel: 'C123', text: 'hello' } }
      let(:expected_log_payload) do
        { message: 'Slack API: posting message', channel_id: 'C123', threaded: false }
      end

      let(:expected_error_message) { 'Slack API error when posting message' }

      subject { api.post_message(**payload) }
    end

    context 'with threading' do
      let(:slack_installation) { build(:slack_integration) }
      let(:api) { described_class.new(slack_installation) }
      let(:api_url) { "#{described_class::BASE_URL}/chat.postMessage" }

      before do
        stub_request(:post, api_url).to_return(
          status: 200, body: { ok: true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'includes thread_ts when provided' do
        api.post_message(channel: 'C123', text: 'hello', thread_ts: '123.456')

        expect(WebMock).to have_requested(:post, api_url)
          .with(body: hash_including('thread_ts' => '123.456'))
      end

      it 'logs threaded as true' do
        expect(Gitlab::IntegrationsLogger).to receive(:info)
          .with(hash_including(threaded: true))

        api.post_message(channel: 'C123', text: 'hello', thread_ts: '123.456')
      end

      it 'includes blocks when provided' do
        api.post_message(channel: 'C123', text: 'hello', blocks: [{ type: 'markdown', text: 'hi' }])

        expect(WebMock).to have_requested(:post, api_url)
          .with(body: hash_including('blocks' => [{ 'type' => 'markdown', 'text' => 'hi' }]))
      end
    end
  end

  describe '#update_message' do
    it_behaves_like 'a Slack API method' do
      let(:action) { 'chat.update' }
      let(:response_body) { { ok: true } }
      let(:payload) { { channel: 'C123', ts: '1.2', text: 'hello' } }
      let(:expected_log_payload) { { message: 'Slack API: updating message', channel_id: 'C123' } }
      let(:expected_error_message) { 'Slack API error when updating message' }

      subject { api.update_message(**payload) }
    end

    context 'with blocks' do
      let(:slack_installation) { build(:slack_integration) }
      let(:api) { described_class.new(slack_installation) }
      let(:api_url) { "#{described_class::BASE_URL}/chat.update" }

      before do
        stub_request(:post, api_url).to_return(
          status: 200, body: { ok: true }.to_json, headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'includes blocks when provided' do
        api.update_message(channel: 'C123', ts: '1.2', text: 'x', blocks: [{ type: 'markdown', text: 'hi' }])

        expect(WebMock).to have_requested(:post, api_url)
          .with(body: hash_including('blocks' => [{ 'type' => 'markdown', 'text' => 'hi' }]))
      end

      it 'sends an empty blocks array to clear existing blocks' do
        api.update_message(channel: 'C123', ts: '1.2', text: 'x', blocks: [])

        expect(WebMock).to have_requested(:post, api_url).with(body: hash_including('blocks' => []))
      end
    end
  end

  describe '#set_status' do
    let(:slack_installation) { build(:slack_integration) }
    let(:api) { described_class.new(slack_installation) }
    let(:api_url) { "#{described_class::BASE_URL}/assistant.threads.setStatus" }

    before do
      stub_request(:post, api_url).to_return(
        status: 200, body: { ok: true }.to_json, headers: { 'Content-Type' => 'application/json' }
      )
    end

    it 'posts channel_id, thread_ts and status' do
      api.set_status(channel: 'C123', thread_ts: '1.2', status: 'is thinking')

      expect(WebMock).to have_requested(:post, api_url)
        .with(body: hash_including('channel_id' => 'C123', 'thread_ts' => '1.2', 'status' => 'is thinking'))
    end

    it 'includes loading_messages when provided' do
      api.set_status(channel: 'C123', thread_ts: '1.2', status: 'x', loading_messages: %w[a b])

      expect(WebMock).to have_requested(:post, api_url).with(body: hash_including('loading_messages' => %w[a b]))
    end

    it 'omits loading_messages when not provided' do
      api.set_status(channel: 'C123', thread_ts: '1.2', status: 'x')

      expect(WebMock).to have_requested(:post, api_url).with { |req| req.body.exclude?('loading_messages') }
    end

    context 'when the Slack API returns an error' do
      before do
        stub_request(:post, api_url).to_return(
          status: 200, body: { ok: false, error: 'boom' }.to_json, headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'logs the error' do
        expect(Gitlab::IntegrationsLogger).to receive(:error)
          .with(hash_including(message: 'Slack API error when setting status'))

        api.set_status(channel: 'C123', thread_ts: '1.2', status: 'x')
      end
    end
  end

  describe '#get' do
    let(:slack_installation) { build(:slack_integration) }
    let(:api_method) { 'conversations.replies' }
    let(:api_url) { "#{described_class::BASE_URL}/#{api_method}" }
    let(:query) { { channel: 'C123', ts: '1234567890.123456' } }

    subject(:get) { described_class.new(slack_installation).get(api_method, query) }

    before do
      stub_request(:get, api_url).with(query: query)
    end

    it 'sends a GET request with query parameters' do
      get

      expect(WebMock).to have_requested(:get, api_url).with(
        query: query,
        headers: {
          'Authorization' => "Bearer #{slack_installation.bot_access_token}",
          'Content-Type' => 'application/json; charset=utf-8'
        })
    end

    it 'returns the response' do
      is_expected.to be_kind_of(HTTParty::Response)
    end

    context 'when the slack installation has no bot token' do
      let(:slack_installation) { build(:slack_integration, :legacy) }

      it 'raises an error' do
        expect { get }.to raise_error(ArgumentError)
      end
    end
  end
end
