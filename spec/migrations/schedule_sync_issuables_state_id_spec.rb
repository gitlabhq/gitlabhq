# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleSyncIssuablesStateId do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:issues) { table(:issues) }
  let(:migration) { described_class.new }
  let(:group) { namespaces.create!(name: 'gitlab', path: 'gitlab') }
  let(:project) { projects.create!(namespace_id: group.id) }

  shared_examples 'scheduling migrations' do
    before do
      Sidekiq::Worker.clear_all
      stub_const("#{described_class.name}::BATCH_SIZE", 2)
    end

    it 'correctly schedules issuable sync background migration' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(migration).to be_scheduled_delayed_migration(120.seconds, resource_1.id, resource_2.id)
          expect(migration).to be_scheduled_delayed_migration(240.seconds, resource_3.id, resource_4.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end

  describe '#up' do
    context 'issues' do
      it 'migrates state column to integer', :sidekiq_might_not_need_inline do
        opened_issue = issues.create!(description: 'first', state: 'opened')
        closed_issue = issues.create!(description: 'second', state: 'closed')
        invalid_state_issue = issues.create!(description: 'fourth', state: 'not valid')

        migrate!

        expect(opened_issue.reload.state_id).to eq(Issue.available_states[:opened])
        expect(closed_issue.reload.state_id).to eq(Issue.available_states[:closed])
        expect(invalid_state_issue.reload.state_id).to be_nil
      end

      it_behaves_like 'scheduling migrations' do
        let(:migration) { described_class::ISSUES_MIGRATION }
        let!(:resource_1) { issues.create!(description: 'first', state: 'opened') }
        let!(:resource_2) { issues.create!(description: 'second', state: 'closed') }
        let!(:resource_3) { issues.create!(description: 'third', state: 'closed') }
        let!(:resource_4) { issues.create!(description: 'fourth', state: 'closed') }
      end
    end

    context 'merge requests' do
      it 'migrates state column to integer', :sidekiq_might_not_need_inline do
        opened_merge_request = merge_requests.create!(state: 'opened', target_project_id: project.id, target_branch: 'feature1', source_branch: 'master')
        closed_merge_request = merge_requests.create!(state: 'closed', target_project_id: project.id, target_branch: 'feature2', source_branch: 'master')
        merged_merge_request = merge_requests.create!(state: 'merged', target_project_id: project.id, target_branch: 'feature3', source_branch: 'master')
        locked_merge_request = merge_requests.create!(state: 'locked', target_project_id: project.id, target_branch: 'feature4', source_branch: 'master')

        migrate!

        expect(opened_merge_request.reload.state_id).to eq(MergeRequest.available_states[:opened])
        expect(closed_merge_request.reload.state_id).to eq(MergeRequest.available_states[:closed])
        expect(merged_merge_request.reload.state_id).to eq(MergeRequest.available_states[:merged])
        expect(locked_merge_request.reload.state_id).to eq(MergeRequest.available_states[:locked])
      end

      it_behaves_like 'scheduling migrations' do
        let(:migration) { described_class::MERGE_REQUESTS_MIGRATION }
        let!(:resource_1) { merge_requests.create!(state: 'opened', target_project_id: project.id, target_branch: 'feature1', source_branch: 'master') }
        let!(:resource_2) { merge_requests.create!(state: 'closed', target_project_id: project.id, target_branch: 'feature2', source_branch: 'master') }
        let!(:resource_3) { merge_requests.create!(state: 'merged', target_project_id: project.id, target_branch: 'feature3', source_branch: 'master') }
        let!(:resource_4) { merge_requests.create!(state: 'locked', target_project_id: project.id, target_branch: 'feature4', source_branch: 'master') }
      end
    end
  end
end
