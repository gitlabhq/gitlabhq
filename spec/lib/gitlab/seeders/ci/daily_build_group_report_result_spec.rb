# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Seeders::Ci::DailyBuildGroupReportResult do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, :success, pipeline: pipeline) }

  subject(:build_report) do
    described_class.new(project)
  end

  describe '#seed' do
    it 'creates daily build results for the project' do
      expect { build_report.seed }.to change {
        Ci::DailyBuildGroupReportResult.count
      }.by(Gitlab::Seeders::Ci::DailyBuildGroupReportResult::COUNT_OF_DAYS)
    end

    it 'matches project data with last report' do
      build_report.seed

      report = project.daily_build_group_report_results.last
      reports_count = project.daily_build_group_report_results.count

      expect(build.group_name).to eq(report.group_name)
      expect(pipeline.source_ref_path).to eq(report.ref_path)
      expect(pipeline.default_branch?).to eq(report.default_branch)
      expect(reports_count).to eq(Gitlab::Seeders::Ci::DailyBuildGroupReportResult::COUNT_OF_DAYS)
    end

    it 'does not raise error on RecordNotUnique' do
      build_report.seed
      build_report.seed

      reports_count = project.daily_build_group_report_results.count

      expect(reports_count).to eq(Gitlab::Seeders::Ci::DailyBuildGroupReportResult::COUNT_OF_DAYS)
    end
  end
end
