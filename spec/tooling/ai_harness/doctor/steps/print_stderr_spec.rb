# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/ai_harness/doctor/steps/print_stderr'

RSpec.describe AiHarness::Doctor::Steps::PrintStderr, feature_category: :tooling do
  before do
    allow($stderr).to receive(:print)
  end

  describe '.print' do
    it 'prints stderr_text from the message content to stderr' do
      message = Gitlab::Fp::Message.new({ stderr_text: 'error output', exit_code: 1 })

      described_class.print(message)

      expect($stderr).to have_received(:print).with('error output')
    end

    it 'returns nil' do
      message = Gitlab::Fp::Message.new({ stderr_text: 'err', exit_code: 1 })

      expect(described_class.print(message)).to be_nil
    end
  end
end
