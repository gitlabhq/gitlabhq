# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DailyBuildGroupReportResult do
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

  describe 'scopes' do
    let_it_be(:project) { create(:project) }
    let(:recent_build_group_report_result) { create(:ci_daily_build_group_report_result, project: project) }
    let(:old_build_group_report_result) do
      create(:ci_daily_build_group_report_result, date: 1.week.ago, project: project)
    end

    describe '.by_projects' do
      subject { described_class.by_projects([project.id]) }

      it 'returns records by projects' do
        expect(subject).to contain_exactly(recent_build_group_report_result, old_build_group_report_result)
      end
    end

    describe '.with_coverage' do
      subject { described_class.with_coverage }

      it 'returns data with coverage' do
        expect(subject).to contain_exactly(recent_build_group_report_result, old_build_group_report_result)
      end
    end

    describe '.with_default_branch' do
      subject(:coverages) { described_class.with_default_branch }

      context 'when coverage for the default branch exist' do
        let!(:recent_build_group_report_result) { create(:ci_daily_build_group_report_result, project: project) }
        let!(:coverage_feature_branch) { create(:ci_daily_build_group_report_result, :on_feature_branch, project: project) }

        it 'returns coverage with the default branch' do
          expect(coverages).to contain_exactly(recent_build_group_report_result)
        end
      end

      context 'when coverage for the default branch does not exist' do
        it 'returns an empty collection' do
          expect(coverages).to be_empty
        end
      end
    end

    describe '.by_date' do
      subject(:coverages) { described_class.by_date(start_date) }

      let!(:coverage_1) { create(:ci_daily_build_group_report_result, date: 1.week.ago) }

      context 'when project has several coverage' do
        let!(:coverage_2) { create(:ci_daily_build_group_report_result, date: 2.weeks.ago) }
        let(:start_date) { 1.week.ago.to_date.to_s }

        it 'returns the coverage from the start_date' do
          expect(coverages).to contain_exactly(coverage_1)
        end
      end

      context 'when start_date is over 90 days' do
        let!(:coverage_2) { create(:ci_daily_build_group_report_result, date: 90.days.ago) }
        let!(:coverage_3) { create(:ci_daily_build_group_report_result, date: 91.days.ago) }
        let(:start_date) { 1.year.ago.to_date.to_s }

        it 'returns the coverage in the last 90 days' do
          expect(coverages).to contain_exactly(coverage_1, coverage_2)
        end
      end

      context 'when start_date is not a string' do
        let!(:coverage_2) { create(:ci_daily_build_group_report_result, date: 90.days.ago) }
        let(:start_date) { 1.week.ago }

        it 'returns the coverage in the last 90 days' do
          expect(coverages).to contain_exactly(coverage_1, coverage_2)
        end
      end
    end
  end
end
