# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DailyBuildGroupReportResult do
  let(:daily_build_group_report_result) { build(:ci_daily_build_group_report_result)}

  describe 'associations' do
    it { is_expected.to belong_to(:last_pipeline) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
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
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let(:recent_build_group_report_result) { create(:ci_daily_build_group_report_result, project: project, group: group) }
    let(:old_build_group_report_result) do
      create(:ci_daily_build_group_report_result, date: 1.week.ago, project: project)
    end

    describe '.by_projects' do
      subject { described_class.by_projects([project.id]) }

      it 'returns records by projects' do
        expect(subject).to contain_exactly(recent_build_group_report_result, old_build_group_report_result)
      end
    end

    describe '.by_group' do
      subject { described_class.by_group(group) }

      it 'returns records by group' do
        expect(subject).to contain_exactly(recent_build_group_report_result)
      end
    end

    describe '.by_ref_path' do
      subject(:coverages) { described_class.by_ref_path(recent_build_group_report_result.ref_path) }

      it 'returns coverages by ref_path' do
        expect(coverages).to contain_exactly(recent_build_group_report_result, old_build_group_report_result)
      end
    end

    describe '.ordered_by_date_and_group_name' do
      subject(:coverages) { described_class.ordered_by_date_and_group_name }

      it 'returns coverages ordered by data and group name' do
        expect(subject).to contain_exactly(recent_build_group_report_result, old_build_group_report_result)
      end
    end

    describe '.by_dates' do
      subject(:coverages) { described_class.by_dates(start_date, end_date) }

      context 'when daily coverages exist during those dates' do
        let(:start_date) { 1.day.ago.to_date.to_s }
        let(:end_date) { Date.current.to_s }

        it 'returns coverages' do
          expect(coverages).to contain_exactly(recent_build_group_report_result)
        end
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
  end
end
