# frozen_string_literal: true

require 'spec_helper'

describe TestSuiteEntity do
  let(:pipeline) { create(:ci_pipeline, :with_test_reports) }
  let(:entity) { described_class.new(pipeline.test_reports.test_suites.each_value.first) }

  describe '#as_json' do
    subject(:as_json) { entity.as_json }

    it 'contains the suite name' do
      expect(as_json).to include(:name)
    end

    it 'contains the total time' do
      expect(as_json).to include(:total_time)
    end

    it 'contains the counts' do
      expect(as_json).to include(:total_count, :success_count, :failed_count, :skipped_count, :error_count)
    end

    it 'contains the test cases' do
      expect(as_json).to include(:test_cases)
      expect(as_json[:test_cases].count).to eq(4)
    end
  end
end
