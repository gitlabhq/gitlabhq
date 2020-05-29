# frozen_string_literal: true

require 'spec_helper'

describe Ci::BuildReportResult do
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
end
