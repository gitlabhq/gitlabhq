# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Mcp::Logger, feature_category: :mcp_server do
  describe '.file_name_noext' do
    it { expect(described_class.file_name_noext).to eq('mcp') }
  end

  describe '#conditional_info', unless: Gitlab.ee? do
    let(:user) { build_stubbed(:user) }
    let(:logger) { described_class.build }

    let(:base_payload) do
      {
        message: 'test',
        event_name: 'tool_call',
        ai_component: 'mcp_server',
        tool_name: 'search',
        Labkit::Fields::GL_USER_ID => user.id
      }
    end

    def log(namespace: nil)
      logger.conditional_info(user,
        message: 'test',
        event_name: 'tool_call',
        ai_component: 'mcp_server',
        namespace: namespace,
        tool_name: 'search',
        expanded: { arguments: { search: 'secret' } })
    end

    it 'never logs the expanded payload' do
      expect(logger).to receive(:info).with(base_payload)

      log
    end

    it 'never logs the expanded payload even when a namespace is given' do
      expect(logger).to receive(:info).with(base_payload)

      log(namespace: build_stubbed(:namespace))
    end
  end
end
