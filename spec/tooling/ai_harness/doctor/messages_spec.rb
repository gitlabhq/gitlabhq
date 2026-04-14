# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../tooling/ai_harness/doctor/messages'

RSpec.describe AiHarness::Doctor::Messages, feature_category: :tooling do
  describe AiHarness::Doctor::Messages::InvalidArguments do
    it 'is a subclass of Gitlab::Fp::Message' do
      expect(described_class.superclass).to eq(Gitlab::Fp::Message)
    end

    it 'stores content hash' do
      message = described_class.new({ stderr_text: 'error', exit_code: 1 })
      expect(message.content).to eq({ stderr_text: 'error', exit_code: 1 })
    end
  end
end
