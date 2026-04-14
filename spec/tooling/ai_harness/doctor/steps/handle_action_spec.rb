# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/ai_harness/doctor/steps/handle_action'

RSpec.describe AiHarness::Doctor::Steps::HandleAction, feature_category: :tooling do
  describe '.handle' do
    context 'when print_help is true' do
      it 'sets stdout_text from HelpText and exit_code 0' do
        context = { results: [], print_help: true, fix: false }

        result = described_class.handle(context)

        expect(result.fetch(:stdout_text)).to include('Usage:')
        expect(result.fetch(:exit_code)).to eq(0)
      end

      it 'does not delegate to PerformDoctorChecks' do
        context = { results: [], print_help: true, fix: false }

        expect(AiHarness::Doctor::Steps::PerformDoctorChecks::Main).not_to receive(:main)

        described_class.handle(context)
      end
    end

    context 'when print_help is false' do
      it 'delegates to PerformDoctorChecks sub-chain' do
        context = { results: [], print_help: false, fix: false }

        expect(AiHarness::Doctor::Steps::PerformDoctorChecks::Main).to receive(:main).with(context).and_return(context)

        described_class.handle(context)
      end
    end

    it 'destructures context with type assertions' do
      expect { described_class.handle({ results: [] }) }.to raise_error(NoMatchingPatternKeyError)
    end
  end
end
