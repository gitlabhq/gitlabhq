# frozen_string_literal: true

require 'spec_helper'

describe TestSuiteEntity do
  let(:pipeline)   { create(:ci_pipeline, :with_test_reports) }
  let(:test_suite) { pipeline.test_reports.test_suites.each_value.first }
  let(:entity)     { described_class.new(test_suite) }

  describe '#as_json' do
    subject(:as_json) { entity.as_json }

    it 'contains the suite name' do
      expect(as_json[:name]).to be_present
    end

    it 'contains the total time' do
      expect(as_json[:total_time]).to be_present
    end

    it 'contains the counts' do
      expect(as_json[:total_count]).to eq(4)
      expect(as_json[:success_count]).to eq(2)
      expect(as_json[:failed_count]).to eq(2)
      expect(as_json[:skipped_count]).to eq(0)
      expect(as_json[:error_count]).to eq(0)
    end

    it 'contains the test cases' do
      expect(as_json[:test_cases].count).to eq(4)
    end

    it 'contains an empty error message' do
      expect(as_json[:suite_error]).to be_nil
    end

    context 'with a suite error' do
      before do
        test_suite.set_suite_error('a really bad error')
      end

      it 'contains the suite name' do
        expect(as_json[:name]).to be_present
      end

      it 'contains the total time' do
        expect(as_json[:total_time]).to be_present
      end

      it 'returns all the counts as 0' do
        expect(as_json[:total_count]).to eq(0)
        expect(as_json[:success_count]).to eq(0)
        expect(as_json[:failed_count]).to eq(0)
        expect(as_json[:skipped_count]).to eq(0)
        expect(as_json[:error_count]).to eq(0)
      end

      it 'returns no test cases' do
        expect(as_json[:test_cases]).to be_empty
      end

      it 'returns a suite error' do
        expect(as_json[:suite_error]).to eq('a really bad error')
      end
    end
  end
end
