# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestCleanupSchedules, schema: 20201103110018 do
  let(:merge_requests) { table(:merge_requests) }
  let(:cleanup_schedules) { table(:merge_request_cleanup_schedules) }
  let(:metrics) { table(:merge_request_metrics) }

  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id) }

  subject { described_class.new }

  describe '#perform' do
    let!(:open_mr) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master') }

    let!(:closed_mr_1) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master', state_id: 2) }
    let!(:closed_mr_2) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master', state_id: 2) }
    let!(:closed_mr_1_metrics) { metrics.create!(merge_request_id: closed_mr_1.id, target_project_id: project.id, latest_closed_at: Time.current, created_at: Time.current, updated_at: Time.current) }
    let!(:closed_mr_2_metrics) { metrics.create!(merge_request_id: closed_mr_2.id, target_project_id: project.id, latest_closed_at: Time.current, created_at: Time.current, updated_at: Time.current) }
    let!(:closed_mr_2_cleanup_schedule) { cleanup_schedules.create!(merge_request_id: closed_mr_2.id, scheduled_at: Time.current) }

    let!(:merged_mr_1) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master', state_id: 3) }
    let!(:merged_mr_2) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master', state_id: 3, updated_at: Time.current) }
    let!(:merged_mr_1_metrics) { metrics.create!(merge_request_id: merged_mr_1.id, target_project_id: project.id, merged_at: Time.current, created_at: Time.current, updated_at: Time.current) }

    let!(:closed_mr_3) { merge_requests.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'master', state_id: 2) }
    let!(:closed_mr_3_metrics) { metrics.create!(merge_request_id: closed_mr_3.id, target_project_id: project.id, latest_closed_at: Time.current, created_at: Time.current, updated_at: Time.current) }

    it 'creates records for all closed and merged merge requests in range' do
      expect(Gitlab::BackgroundMigration::Logger).to receive(:info).with(
        message: 'Backfilled merge_request_cleanup_schedules records',
        count: 3
      )

      subject.perform(open_mr.id, merged_mr_2.id)

      aggregate_failures do
        expect(cleanup_schedules.all.pluck(:merge_request_id))
          .to contain_exactly(closed_mr_1.id, closed_mr_2.id, merged_mr_1.id, merged_mr_2.id)
        expect(cleanup_schedules.find_by(merge_request_id: closed_mr_1.id).scheduled_at.to_s)
          .to eq((closed_mr_1_metrics.latest_closed_at + 14.days).to_s)
        expect(cleanup_schedules.find_by(merge_request_id: closed_mr_2.id).scheduled_at.to_s)
          .to eq(closed_mr_2_cleanup_schedule.scheduled_at.to_s)
        expect(cleanup_schedules.find_by(merge_request_id: merged_mr_1.id).scheduled_at.to_s)
          .to eq((merged_mr_1_metrics.merged_at + 14.days).to_s)
        expect(cleanup_schedules.find_by(merge_request_id: merged_mr_2.id).scheduled_at.to_s)
          .to eq((merged_mr_2.updated_at + 14.days).to_s)
      end
    end
  end
end
