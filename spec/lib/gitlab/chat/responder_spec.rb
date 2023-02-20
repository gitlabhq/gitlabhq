# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Chat::Responder, feature_category: :integrations do
  describe '.responder_for' do
    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(use_response_url_for_chat_responder: false)
      end

      context 'using a regular build' do
        it 'returns nil' do
          build = create(:ci_build)

          expect(described_class.responder_for(build)).to be_nil
        end
      end

      context 'using a chat build' do
        it 'returns the responder for the build' do
          pipeline = create(:ci_pipeline)
          build = create(:ci_build, pipeline: pipeline)
          integration = double(:integration, chat_responder: Gitlab::Chat::Responder::Slack)
          chat_name = double(:chat_name, integration: integration)
          chat_data = double(:chat_data, chat_name: chat_name)

          allow(pipeline)
            .to receive(:chat_data)
            .and_return(chat_data)

          expect(described_class.responder_for(build))
            .to be_an_instance_of(Gitlab::Chat::Responder::Slack)
        end
      end
    end

    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(use_response_url_for_chat_responder: true)
      end

      context 'using a regular build' do
        it 'returns nil' do
          build = create(:ci_build)

          expect(described_class.responder_for(build)).to be_nil
        end
      end

      context 'using a chat build' do
        let(:chat_name) { create(:chat_name, chat_id: 'U123') }
        let(:pipeline) do
          pipeline = create(:ci_pipeline)
          pipeline.create_chat_data!(
            response_url: 'https://hooks.slack.com/services/12345',
            chat_name_id: chat_name.id
          )
          pipeline
        end

        let(:build) { create(:ci_build, pipeline: pipeline) }
        let(:responder) { described_class.new(build) }

        it 'returns the responder for the build' do
          expect(described_class.responder_for(build))
            .to be_an_instance_of(Gitlab::Chat::Responder::Slack)
        end
      end
    end
  end
end
