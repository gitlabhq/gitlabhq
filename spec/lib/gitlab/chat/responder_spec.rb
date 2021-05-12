# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Chat::Responder do
  describe '.responder_for' do
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
end
