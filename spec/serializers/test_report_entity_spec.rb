# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestReportEntity do
  let(:pipeline) { create(:ci_pipeline, :with_test_reports) }
  let(:entity) { described_class.new(pipeline.test_reports) }

  describe '#as_json' do
    subject(:as_json) { entity.as_json }

    it 'contains the total time' do
      expect(as_json).to include(:total_time)
    end

    it 'contains the counts' do
      expect(as_json).to include(:total_count, :success_count, :failed_count, :skipped_count, :error_count)
    end

    it 'contains the test suites' do
      expect(as_json).to include(:test_suites)
      expect(as_json[:test_suites].count).to eq(1)
    end
  end
end
