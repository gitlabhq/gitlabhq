# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectsWithCoverage, :suppress_gitlab_schemas_validate_connection do
  let(:projects) { table(:projects) }
  let(:ci_pipelines) { table(:ci_pipelines) }
  let(:ci_daily_build_group_report_results) { table(:ci_daily_build_group_report_results) }
  let(:group) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:project_1) { projects.create!(namespace_id: group.id) }
  let(:project_2) { projects.create!(namespace_id: group.id) }
  let(:pipeline_1) { ci_pipelines.create!(project_id: project_1.id) }
  let(:pipeline_2) { ci_pipelines.create!(project_id: project_2.id) }
  let(:pipeline_3) { ci_pipelines.create!(project_id: project_2.id) }

  describe '#up' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)
      stub_const("#{described_class}::SUB_BATCH_SIZE", 1)

      ci_daily_build_group_report_results.create!(
        id: 1,
        project_id: project_1.id,
        date: 3.days.ago,
        last_pipeline_id: pipeline_1.id,
        ref_path: 'main',
        group_name: 'rspec',
        data: { coverage: 95.0 },
        default_branch: true,
        group_id: group.id
      )

      ci_daily_build_group_report_results.create!(
        id: 2,
        project_id: project_2.id,
        date: 2.days.ago,
        last_pipeline_id: pipeline_2.id,
        ref_path: 'main',
        group_name: 'rspec',
        data: { coverage: 95.0 },
        default_branch: true,
        group_id: group.id
      )

      ci_daily_build_group_report_results.create!(
        id: 3,
        project_id: project_2.id,
        date: 1.day.ago,
        last_pipeline_id: pipeline_3.id,
        ref_path: 'test_branch',
        group_name: 'rspec',
        data: { coverage: 95.0 },
        default_branch: false,
        group_id: group.id
      )
    end

    it 'schedules BackfillProjectsWithCoverage background jobs', :aggregate_failures do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, 1, 2, 1)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 3, 3, 1)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
