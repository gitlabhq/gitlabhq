# frozen_string_literal: true

require 'spec_helper'

describe Ci::DailyBuildGroupReportResult do
  let(:daily_build_group_report_result) { build(:ci_daily_build_group_report_result)}

  describe 'associations' do
    it { is_expected.to belong_to(:last_pipeline) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    context 'when attributes are valid' do
      it 'returns no errors' do
        expect(daily_build_group_report_result).to be_valid
      end
    end

    context 'when data is invalid' do
      it 'returns errors' do
        daily_build_group_report_result.data = { invalid: 'data' }

        expect(daily_build_group_report_result).to be_invalid
        expect(daily_build_group_report_result.errors.full_messages).to eq(["Data must be a valid json schema"])
      end
    end
  end

  describe '.upsert_reports' do
    let!(:rspec_coverage) do
      create(
        :ci_daily_build_group_report_result,
        group_name: 'rspec',
        date: '2020-03-09',
        data: { coverage: 71.2 }
      )
    end
    let!(:new_pipeline) { create(:ci_pipeline) }

    it 'creates or updates matching report results' do
      described_class.upsert_reports([
        {
          project_id: rspec_coverage.project_id,
          ref_path: rspec_coverage.ref_path,
          last_pipeline_id: new_pipeline.id,
          date: rspec_coverage.date,
          group_name: 'rspec',
          data: { 'coverage' => 81.0 }
        },
        {
          project_id: rspec_coverage.project_id,
          ref_path: rspec_coverage.ref_path,
          last_pipeline_id: new_pipeline.id,
          date: rspec_coverage.date,
          group_name: 'karma',
          data: { 'coverage' => 87.0 }
        }
      ])

      rspec_coverage.reload

      expect(rspec_coverage).to have_attributes(
        last_pipeline_id: new_pipeline.id,
        data: { 'coverage' => 81.0 }
      )

      expect(described_class.find_by_group_name('karma')).to have_attributes(
        project_id: rspec_coverage.project_id,
        ref_path: rspec_coverage.ref_path,
        last_pipeline_id: new_pipeline.id,
        date: rspec_coverage.date,
        data: { 'coverage' => 87.0 }
      )
    end

    context 'when given data is empty' do
      it 'does nothing' do
        expect { described_class.upsert_reports([]) }.not_to raise_error
      end
    end
  end
end
