# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Chat::Responder::Slack, feature_category: :integrations do
  let(:chat_name) { create(:chat_name, chat_id: 'U123') }

  let(:pipeline) do
    pipeline = create(:ci_pipeline)

    pipeline.create_chat_data!(
      response_url: 'http://example.com',
      project_id: pipeline.project_id,
      chat_name_id: chat_name.id
    )

    pipeline
  end

  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:responder) { described_class.new(build) }

  describe '#send_response' do
    before do
      allow(Gitlab::HTTP).to receive(:post).and_call_original

      stub_request(:post, "http://example.com").to_return(status: 200)
    end

    it 'sends a response back to Slack' do
      expect(Gitlab::HTTP).to receive(:post).with(
        'http://example.com',
        { headers: { Accept: 'application/json' }, body: 'hello'.to_json }
      )

      responder.send_response('hello')
    end

    it 'logs failure to send a response back to Slack' do
      stub_request(:post, "http://example.com").to_return(status: 400)

      expect(Gitlab::HTTP).to receive(:post).with(
        'http://example.com',
        { headers: { Accept: 'application/json' }, body: 'hello'.to_json }
      )

      expect(Gitlab::AppLogger)
        .to receive(:warn)
        .with(hash_including(code: 400, message: 'Posting chat response failed'))
        .and_call_original

      responder.send_response('hello')
    end
  end

  describe '#success' do
    it 'returns the output for a successful build' do
      expect(responder)
        .to receive(:send_response)
        .with(hash_including(text: /<@U123>:.+hello/, response_type: :in_channel))

      responder.success('hello')
    end

    it 'limits the output to a fixed size' do
      expect(responder)
        .to receive(:send_response)
        .with(hash_including(text: /The output is too large/))

      responder.success('a' * 4000)
    end

    it 'does not send a response if the output is empty' do
      expect(responder).not_to receive(:send_response)
      expect(Gitlab::AppLogger)
        .to receive(:info)
        .with(hash_including(message: 'Chat pipeline successful, but output is empty'))
        .and_call_original

      responder.success('')
    end
  end

  describe '#failure' do
    it 'returns the output for a failed build' do
      expect(responder).to receive(:send_response).with(
        hash_including(
          text: /<@U123>:.+Sorry, the build failed!/,
          response_type: :in_channel
        )
      )

      responder.failure
    end
  end

  describe '#scheduled_output' do
    it 'returns the output for a scheduled build' do
      output = responder.scheduled_output

      expect(output).to eq({ text: '' })
    end
  end
end
