# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../../tooling/ai_harness/doctor/steps/perform_doctor_checks/format_output'

RSpec.describe AiHarness::Doctor::Steps::PerformDoctorChecks::FormatOutput, feature_category: :tooling do
  describe '.format' do
    context 'when all checks pass' do
      let(:context) do
        {
          results: [
            { name: 'Check A', status: 'OK', details: [] },
            { name: 'Check B', status: 'OK', details: [] }
          ]
        }
      end

      it 'formats each check as a line with dots and status' do
        result = described_class.format(context)

        expect(result[:stdout_text]).to include('Check: Check A')
        expect(result[:stdout_text]).to include('OK')
        expect(result[:stdout_text]).to include('Check: Check B')
      end
    end

    context 'when a check has FAIL status' do
      let(:context) do
        {
          results: [
            { name: 'Check A', status: 'OK', details: [] },
            { name: 'Check B', status: 'FAIL', details: ['Something broke'] }
          ]
        }
      end

      it 'includes detail lines indented under the check' do
        result = described_class.format(context)

        expect(result[:stdout_text]).to include('  Something broke')
      end
    end

    context 'when a check has FIXED status' do
      let(:context) do
        {
          results: [
            { name: 'Check A', status: 'FIXED', details: ['Repaired'] },
            { name: 'Check B', status: 'OK', details: [] }
          ]
        }
      end

      it 'includes FIXED in output' do
        result = described_class.format(context)

        expect(result[:stdout_text]).to include('FIXED')
      end
    end

    it 'returns the context hash with output_text added' do
      context = { results: [{ name: 'X', status: 'OK', details: [] }] }

      result = described_class.format(context)

      expect(result).to include(:stdout_text, :results)
      expect(result).not_to include(:exit_code)
    end

    it 'raises when a result hash is missing a required key' do
      context = { results: [{ name: 'X', details: [] }] }

      expect { described_class.format(context) }.to raise_error(NoMatchingPatternKeyError)
    end

    it 'destructures context with type assertions' do
      expect { described_class.format({ results: 'not_array' }) }.to raise_error(NoMatchingPatternError)
    end
  end
end
