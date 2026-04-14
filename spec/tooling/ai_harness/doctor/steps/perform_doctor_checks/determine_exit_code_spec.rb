# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../../tooling/ai_harness/doctor/steps/perform_doctor_checks/determine_exit_code'

RSpec.describe AiHarness::Doctor::Steps::PerformDoctorChecks::DetermineExitCode, feature_category: :tooling do
  describe '.determine' do
    context 'when all checks pass' do
      it 'sets exit_code to 0' do
        context = { results: [{ name: 'A', status: 'OK', details: [] }] }

        result = described_class.determine(context)

        expect(result[:exit_code]).to eq(0)
      end
    end

    context 'when a check has FAIL status' do
      it 'sets exit_code to 1' do
        context = {
          results: [
            { name: 'A', status: 'OK', details: [] },
            { name: 'B', status: 'FAIL', details: ['broken'] }
          ]
        }

        result = described_class.determine(context)

        expect(result[:exit_code]).to eq(1)
      end
    end

    context 'when a check has FIXED status' do
      it 'sets exit_code to 0 (FIXED does not cause failure)' do
        context = { results: [{ name: 'A', status: 'FIXED', details: [] }] }

        result = described_class.determine(context)

        expect(result[:exit_code]).to eq(0)
      end
    end

    context 'when FIXED and FAIL both present' do
      it 'sets exit_code to 1 (FAIL takes precedence)' do
        context = {
          results: [
            { name: 'A', status: 'FIXED', details: [] },
            { name: 'B', status: 'FAIL', details: ['unfixable'] }
          ]
        }

        result = described_class.determine(context)

        expect(result[:exit_code]).to eq(1)
      end
    end

    it 'returns the context hash' do
      context = { results: [{ name: 'X', status: 'OK', details: [] }] }

      result = described_class.determine(context)

      expect(result).to include(:results, :exit_code)
      expect(result).to equal(context)
    end

    it 'destructures context with type assertions' do
      expect { described_class.determine({ results: 'not_array' }) }.to raise_error(NoMatchingPatternError)
    end
  end
end
