# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSuiteSummaryEntity do
  let(:pipeline) { create(:ci_pipeline, :with_report_results) }
  let(:entity) { described_class.new(pipeline.test_report_summary.test_suites.each_value.first) }

  describe '#as_json' do
    subject(:as_json) { entity.as_json }

    it 'contains the total time' do
      expect(as_json).to include(:total_time)
    end

    it 'contains the counts' do
      expect(as_json).to include(:total_count, :success_count, :failed_count, :skipped_count, :error_count)
    end

    it 'contains the build_ids' do
      expect(as_json).to include(:build_ids)
    end

    it 'contains the suite_error' do
      expect(as_json).to include(:suite_error)
    end
  end
end
