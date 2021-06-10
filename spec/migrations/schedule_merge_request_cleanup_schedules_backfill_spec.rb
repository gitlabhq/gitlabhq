# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ScheduleMergeRequestCleanupSchedulesBackfill, :sidekiq, schema: 20201023114628 do
  let(:merge_requests) { table(:merge_requests) }
  let(:cleanup_schedules) { table(:merge_request_cleanup_schedules) }

  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id) }

  describe '#up' do
    let!(:open_mr) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master') }

    let!(:closed_mr_1) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master', state_id: 2) }
    let!(:closed_mr_2) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master', state_id: 2) }

    let!(:merged_mr_1) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master', state_id: 3) }
    let!(:merged_mr_2) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master', state_id: 3) }

    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)
    end

    it 'schedules BackfillMergeRequestCleanupSchedules background jobs' do
      Sidekiq::Testing.fake! do
        migrate!

        aggregate_failures do
          expect(described_class::MIGRATION)
            .to be_scheduled_delayed_migration(2.minutes, closed_mr_1.id, closed_mr_2.id)
          expect(described_class::MIGRATION)
            .to be_scheduled_delayed_migration(4.minutes, merged_mr_1.id, merged_mr_2.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
