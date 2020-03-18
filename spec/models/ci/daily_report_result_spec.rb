# frozen_string_literal: true

require 'spec_helper'

describe Ci::DailyReportResult do
  describe '.upsert_reports' do
    let!(:rspec_coverage) do
      create(
        :ci_daily_report_result,
        title: 'rspec',
        date: '2020-03-09',
        value: 71.2
      )
    end
    let!(:new_pipeline) { create(:ci_pipeline) }

    it 'creates or updates matching report results' do
      described_class.upsert_reports([
        {
          project_id: rspec_coverage.project_id,
          ref_path: rspec_coverage.ref_path,
          param_type: described_class.param_types[rspec_coverage.param_type],
          last_pipeline_id: new_pipeline.id,
          date: rspec_coverage.date,
          title: 'rspec',
          value: 81.0
        },
        {
          project_id: rspec_coverage.project_id,
          ref_path: rspec_coverage.ref_path,
          param_type: described_class.param_types[rspec_coverage.param_type],
          last_pipeline_id: new_pipeline.id,
          date: rspec_coverage.date,
          title: 'karma',
          value: 87.0
        }
      ])

      rspec_coverage.reload

      expect(rspec_coverage).to have_attributes(
        last_pipeline_id: new_pipeline.id,
        value: 81.0
      )

      expect(described_class.find_by_title('karma')).to have_attributes(
        project_id: rspec_coverage.project_id,
        ref_path: rspec_coverage.ref_path,
        param_type: rspec_coverage.param_type,
        last_pipeline_id: new_pipeline.id,
        date: rspec_coverage.date,
        value: 87.0
      )
    end

    context 'when given data is empty' do
      it 'does nothing' do
        expect { described_class.upsert_reports([]) }.not_to raise_error
      end
    end
  end
end
