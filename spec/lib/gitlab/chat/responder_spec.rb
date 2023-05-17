# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Chat::Responder, feature_category: :integrations do
  describe '.responder_for' do
    context 'using a regular build' do
      it 'returns nil' do
        build = create(:ci_build)

        expect(described_class.responder_for(build)).to be_nil
      end
    end

    context 'using a chat build' do
      let_it_be(:pipeline) { create(:ci_pipeline) }
      let_it_be(:build) { create(:ci_build, pipeline: pipeline) }

      context "when response_url starts with 'https://hooks.slack.com/'" do
        before do
          pipeline.build_chat_data(response_url: 'https://hooks.slack.com/services/12345', chat_name_id: 'U123')
        end

        it { expect(described_class.responder_for(build)).to be_an_instance_of(Gitlab::Chat::Responder::Slack) }
      end

      context "when response_url does not start with 'https://hooks.slack.com/'" do
        before do
          pipeline.build_chat_data(response_url: 'https://mattermost.example.com/services/12345', chat_name_id: 'U123')
        end

        it { expect(described_class.responder_for(build)).to be_an_instance_of(Gitlab::Chat::Responder::Mattermost) }
      end
    end
  end
end
