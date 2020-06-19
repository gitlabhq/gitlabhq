# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSuiteEntity do
  let(:pipeline) { create(:ci_pipeline, :with_test_reports) }
  let(:test_suite) { pipeline.test_reports.test_suites.each_value.first }
  let(:user) { create(:user) }
  let(:request) { double('request', current_user: user) }

  subject { described_class.new(test_suite, request: request).as_json }

  context 'when details option is not present' do
    it 'does not expose suite error and test cases', :aggregate_failures do
      expect(subject).not_to include(:test_cases)
      expect(subject).not_to include(:suite_error)
    end
  end

  context 'when details option is present' do
    subject { described_class.new(test_suite, request: request, details: true).as_json }

    it 'contains the suite name' do
      expect(subject[:name]).to be_present
    end

    it 'contains the total time' do
      expect(subject[:total_time]).to be_present
    end

    it 'contains the counts' do
      expect(subject[:total_count]).to eq(4)
      expect(subject[:success_count]).to eq(2)
      expect(subject[:failed_count]).to eq(2)
      expect(subject[:skipped_count]).to eq(0)
      expect(subject[:error_count]).to eq(0)
    end

    it 'contains the test cases' do
      expect(subject[:test_cases].count).to eq(4)
    end

    it 'contains an empty error message' do
      expect(subject[:suite_error]).to be_nil
    end

    context 'with a suite error' do
      before do
        test_suite.set_suite_error('a really bad error')
      end

      it 'contains the suite name' do
        expect(subject[:name]).to be_present
      end

      it 'contains the total time' do
        expect(subject[:total_time]).to be_present
      end

      it 'returns all the counts as 0' do
        expect(subject[:total_count]).to eq(0)
        expect(subject[:success_count]).to eq(0)
        expect(subject[:failed_count]).to eq(0)
        expect(subject[:skipped_count]).to eq(0)
        expect(subject[:error_count]).to eq(0)
      end

      it 'returns no test cases' do
        expect(subject[:test_cases]).to be_empty
      end

      it 'returns a suite error' do
        expect(subject[:suite_error]).to eq('a really bad error')
      end
    end
  end
end
