# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Chat::Responder::Mattermost, feature_category: :integrations do
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
    it 'sends a response back to Slack' do
      expect(Gitlab::HTTP).to receive(:post).with(
        'http://example.com',
        { headers: { 'Content-Type': 'application/json' }, body: 'hello'.to_json }
      )

      responder.send_response('hello')
    end
  end

  describe '#success' do
    it 'returns the output for a successful build' do
      expect(responder)
        .to receive(:send_response)
        .with(
          hash_including(
            response_type: :in_channel,
            attachments: array_including(
              a_hash_including(
                text: /#{pipeline.chat_data.chat_name.user.name}.*completed successfully/,
                fields: array_including(
                  a_hash_including(value: /##{build.id}/),
                  a_hash_including(value: build.name),
                  a_hash_including(value: "```shell\nscript output\n```")
                )
              )
            )
          )
        )

      responder.success('[0;m[32;1mscript output[0;m')
    end

    it 'limits the output to a fixed size' do
      expect(responder)
        .to receive(:send_response)
        .with(
          hash_including(
            response_type: :in_channel,
            attachments: array_including(
              a_hash_including(
                fields: array_including(
                  a_hash_including(value: /The output is too large/)
                )
              )
            )
          )
        )

      responder.success('a' * 4000)
    end

    it 'does not send a response if the output is empty' do
      expect(responder).not_to receive(:send_response)

      responder.success('')
    end
  end

  describe '#failure' do
    it 'returns the output for a failed build' do
      expect(responder)
        .to receive(:send_response)
        .with(
          hash_including(
            response_type: :in_channel,
            attachments: array_including(
              a_hash_including(
                text: /#{pipeline.chat_data.chat_name.user.name}.*failed/,
                fields: array_including(
                  a_hash_including(value: /##{build.id}/),
                  a_hash_including(value: build.name)
                )
              )
            )
          )
        )

      responder.failure
    end
  end

  describe '#scheduled_output' do
    it 'returns the output for a scheduled build' do
      output = responder.scheduled_output

      expect(output).to match(
        hash_including(
          response_type: :ephemeral,
          text: /##{build.id}/
        )
      )
    end
  end
end
