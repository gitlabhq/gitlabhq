# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestReportSummaryEntity do
  let(:pipeline) { create(:ci_pipeline, :with_report_results) }
  let(:entity) { described_class.new(pipeline.test_report_summary) }

  describe '#as_json' do
    subject(:as_json) { entity.as_json }

    it 'contains the total' do
      expect(as_json).to include(:total)
    end

    context 'when summary has test suites' do
      it 'contains the test suites', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/463029' do
        expect(as_json).to include(:test_suites)
        expect(as_json[:test_suites].count).to eq(1)
      end

      it 'contains build_ids', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/463030' do
        expect(as_json[:test_suites].first).to include(:build_ids)
      end
    end
  end
end
