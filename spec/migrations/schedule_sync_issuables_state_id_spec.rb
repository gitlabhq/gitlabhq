# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190214112022_schedule_sync_issuables_state_id.rb')

describe ScheduleSyncIssuablesStateId, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:issues) { table(:issues) }
  let(:migration) { described_class.new }

  before do
    @group = namespaces.create!(name: 'gitlab', path: 'gitlab')
    @project = projects.create!(namespace_id: @group.id)
  end

  shared_examples 'scheduling migrations' do
    before do
      Sidekiq::Worker.clear_all
      stub_const("#{described_class.name}::BATCH_SIZE", 2)
    end

    it 'correctly schedules issuable sync background migration' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migrate!

          expect(migration).to be_scheduled_delayed_migration(5.minutes, resource_1.id, resource_2.id)
          expect(migration).to be_scheduled_delayed_migration(10.minutes, resource_3.id, resource_4.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end

  shared_examples 'rescheduling migrations' do
    before do
      Sidekiq::Worker.clear_all
    end

    it 'reschedules migrations when should wait for dead tuple vacuum' do
      worker = worker_class.new

      Sidekiq::Testing.fake! do
        allow(worker).to receive(:wait_for_deadtuple_vacuum?) { true }

        worker.perform(resource_1.id, resource_2.id)

        expect(worker_class.name.demodulize).to be_scheduled_delayed_migration(5.minutes, resource_1.id, resource_2.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      end
    end
  end

  describe '#up' do
    context 'issues' do
      it 'migrates state column to integer' do
        opened_issue = issues.create!(description: 'first', state: 'opened')
        closed_issue = issues.create!(description: 'second', state: 'closed')
        invalid_state_issue = issues.create!(description: 'fourth', state: 'not valid')
        nil_state_issue = issues.create!(description: 'third', state: nil)

        migrate!

        expect(opened_issue.reload.state_id).to eq(Issue.available_states[:opened])
        expect(closed_issue.reload.state_id).to eq(Issue.available_states[:closed])
        expect(invalid_state_issue.reload.state_id).to be_nil
        expect(nil_state_issue.reload.state_id).to be_nil
      end

      it_behaves_like 'scheduling migrations' do
        let(:migration) { described_class::ISSUES_MIGRATION }
        let!(:resource_1) { issues.create!(description: 'first', state: 'opened') }
        let!(:resource_2) { issues.create!(description: 'second', state: 'closed') }
        let!(:resource_3) { issues.create!(description: 'third', state: 'closed') }
        let!(:resource_4) { issues.create!(description: 'fourth', state: 'closed') }
      end

      it_behaves_like 'rescheduling migrations' do
        let(:worker_class) { Gitlab::BackgroundMigration::SyncIssuesStateId }
        let!(:resource_1) { issues.create!(description: 'first', state: 'opened') }
        let!(:resource_2) { issues.create!(description: 'second', state: 'closed') }
      end
    end

    context 'merge requests' do
      it 'migrates state column to integer' do
        opened_merge_request = merge_requests.create!(state: 'opened', target_project_id: @project.id, target_branch: 'feature1', source_branch: 'master')
        closed_merge_request = merge_requests.create!(state: 'closed', target_project_id: @project.id, target_branch: 'feature2', source_branch: 'master')
        merged_merge_request = merge_requests.create!(state: 'merged', target_project_id: @project.id, target_branch: 'feature3', source_branch: 'master')
        locked_merge_request = merge_requests.create!(state: 'locked', target_project_id: @project.id, target_branch: 'feature4', source_branch: 'master')
        invalid_state_merge_request = merge_requests.create!(state: 'not valid', target_project_id: @project.id, target_branch: 'feature5', source_branch: 'master')

        migrate!

        expect(opened_merge_request.reload.state_id).to eq(MergeRequest.available_states[:opened])
        expect(closed_merge_request.reload.state_id).to eq(MergeRequest.available_states[:closed])
        expect(merged_merge_request.reload.state_id).to eq(MergeRequest.available_states[:merged])
        expect(locked_merge_request.reload.state_id).to eq(MergeRequest.available_states[:locked])
        expect(invalid_state_merge_request.reload.state_id).to be_nil
      end

      it_behaves_like 'scheduling migrations' do
        let(:migration) { described_class::MERGE_REQUESTS_MIGRATION }
        let!(:resource_1) { merge_requests.create!(state: 'opened', target_project_id: @project.id, target_branch: 'feature1', source_branch: 'master') }
        let!(:resource_2) { merge_requests.create!(state: 'closed', target_project_id: @project.id, target_branch: 'feature2', source_branch: 'master') }
        let!(:resource_3) { merge_requests.create!(state: 'merged', target_project_id: @project.id, target_branch: 'feature3', source_branch: 'master') }
        let!(:resource_4) { merge_requests.create!(state: 'locked', target_project_id: @project.id, target_branch: 'feature4', source_branch: 'master') }
      end

      it_behaves_like 'rescheduling migrations' do
        let(:worker_class) { Gitlab::BackgroundMigration::SyncMergeRequestsStateId }
        let(:resource_1) { merge_requests.create!(state: 'opened', target_project_id: @project.id, target_branch: 'feature1', source_branch: 'master') }
        let(:resource_2) { merge_requests.create!(state: 'closed', target_project_id: @project.id, target_branch: 'feature2', source_branch: 'master') }
      end
    end
  end
end
