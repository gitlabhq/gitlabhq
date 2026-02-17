# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::AiContext, feature_category: :product_analytics do
  describe '#to_context' do
    let(:properties) do
      {
        session_id: 'session-123',
        workflow_id: 'workflow-456',
        model_name: 'gpt-4',
        model_provider: 'anthropic'
      }
    end

    subject(:context_instance) { described_class.new(properties).to_context }

    it 'returns a SnowplowTracker::SelfDescribingJson' do
      expect(context_instance).to be_a(SnowplowTracker::SelfDescribingJson)
    end

    it 'returns the correct data payload' do
      json = context_instance.to_json

      expect(json[:data]).to include(
        session_id: 'session-123',
        workflow_id: 'workflow-456',
        model_name: 'gpt-4',
        model_provider: 'anthropic'
      )
    end

    it 'uses the correct schema URL' do
      expect(context_instance.to_json[:schema]).to eq('iglu:com.gitlab/ai_context/jsonschema/1-0-0')
    end
  end

  describe '#to_h' do
    let(:properties) do
      {
        session_id: 'session-123',
        workflow_id: 'workflow-456',
        flow_type: 'completion',
        agent_name: 'code-assistant',
        model_name: 'gpt-4',
        input_tokens: 100,
        output_tokens: 50
      }
    end

    subject(:context_hash) { described_class.new(properties).to_h }

    it 'returns a hash with the expected keys' do
      expect(context_hash).to include(
        session_id: 'session-123',
        workflow_id: 'workflow-456',
        flow_type: 'completion',
        agent_name: 'code-assistant',
        model_name: 'gpt-4',
        input_tokens: 100,
        output_tokens: 50
      )
    end

    context 'when properties is nil' do
      let(:properties) { nil }

      it 'returns a hash with nil values' do
        expect(context_hash).to eq(
          session_id: nil,
          workflow_id: nil,
          flow_type: nil,
          agent_name: nil,
          agent_type: nil,
          input_tokens: nil,
          output_tokens: nil,
          total_tokens: nil,
          ephemeral_5m_input_tokens: nil,
          ephemeral_1h_input_tokens: nil,
          cache_read: nil,
          model_engine: nil,
          model_name: nil,
          model_provider: nil,
          flow_version: nil,
          flow_registry_version: nil
        )
      end
    end
  end
end
