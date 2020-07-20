# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildReportResult do
  let(:build_report_result) { build(:ci_build_report_result, :with_junit_success) }

  describe 'associations' do
    it { is_expected.to belong_to(:build) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:build) }

    context 'when attributes are valid' do
      it 'returns no errors' do
        expect(build_report_result).to be_valid
      end
    end

    context 'when data is invalid' do
      it 'returns errors' do
        build_report_result.data = { invalid: 'data' }

        expect(build_report_result).to be_invalid
        expect(build_report_result.errors.full_messages).to eq(["Data must be a valid json schema"])
      end
    end
  end

  describe '#tests_name' do
    it 'returns the suite name' do
      expect(build_report_result.tests_name).to eq("rspec")
    end
  end

  describe '#tests_duration' do
    it 'returns the suite duration' do
      expect(build_report_result.tests_duration).to eq(0.42)
    end
  end

  describe '#tests_success' do
    it 'returns the success count' do
      expect(build_report_result.tests_success).to eq(2)
    end
  end

  describe '#tests_failed' do
    it 'returns the failed count' do
      expect(build_report_result.tests_failed).to eq(0)
    end
  end

  describe '#tests_errored' do
    it 'returns the errored count' do
      expect(build_report_result.tests_errored).to eq(0)
    end
  end

  describe '#tests_skipped' do
    it 'returns the skipped count' do
      expect(build_report_result.tests_skipped).to eq(0)
    end
  end

  describe '#tests_total' do
    it 'returns the total count' do
      expect(build_report_result.tests_total).to eq(2)
    end
  end
end
