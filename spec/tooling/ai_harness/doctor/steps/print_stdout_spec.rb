# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/ai_harness/doctor/steps/print_stdout'

RSpec.describe AiHarness::Doctor::Steps::PrintStdout, feature_category: :tooling do
  before do
    allow($stdout).to receive(:print)
  end

  describe '.print' do
    it 'prints stdout_text from the context to stdout' do
      context = { stdout_text: 'check results', exit_code: 0 }

      described_class.print(context)

      expect($stdout).to have_received(:print).with('check results')
    end

    it 'returns nil' do
      context = { stdout_text: 'text', exit_code: 0 }

      expect(described_class.print(context)).to be_nil
    end
  end
end
