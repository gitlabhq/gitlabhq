# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleSyncIssuablesStateIdWhereNil do
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

          expect(migration).to be_scheduled_delayed_migration(120.seconds, resource_1.id, resource_3.id)
          expect(migration).to be_scheduled_delayed_migration(240.seconds, resource_5.id, resource_5.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end

  describe '#up' do
    context 'issues' do
      it_behaves_like 'scheduling migrations' do
        let(:migration) { described_class::ISSUES_MIGRATION }
        let!(:resource_1) { issues.create!(description: 'first', state: 'opened', state_id: nil) }
        let!(:resource_2) { issues.create!(description: 'second', state: 'closed', state_id: 2) }
        let!(:resource_3) { issues.create!(description: 'third', state: 'closed', state_id: nil) }
        let!(:resource_4) { issues.create!(description: 'fourth', state: 'closed', state_id: 2) }
        let!(:resource_5) { issues.create!(description: 'fifth', state: 'closed', state_id: nil) }
      end
    end

    context 'merge requests' do
      it_behaves_like 'scheduling migrations' do
        let(:migration) { described_class::MERGE_REQUESTS_MIGRATION }
        let!(:resource_1) { merge_requests.create!(state: 'opened', state_id: nil, target_project_id: project.id, target_branch: 'feature1', source_branch: 'master') }
        let!(:resource_2) { merge_requests.create!(state: 'closed', state_id: 2, target_project_id: project.id, target_branch: 'feature2', source_branch: 'master') }
        let!(:resource_3) { merge_requests.create!(state: 'merged', state_id: nil, target_project_id: project.id, target_branch: 'feature3', source_branch: 'master') }
        let!(:resource_4) { merge_requests.create!(state: 'locked', state_id: 3, target_project_id: project.id, target_branch: 'feature4', source_branch: 'master') }
        let!(:resource_5) { merge_requests.create!(state: 'locked', state_id: nil, target_project_id: project.id, target_branch: 'feature4', source_branch: 'master') }
      end
    end
  end
end
