# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixAndBackfillProjectNamespacesForProjectsWithDuplicateName, :migration, feature_category: :projects do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  let!(:group) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }
  let!(:project_namespace) { namespaces.create!(name: 'project2', path: 'project2', type: 'Project') }
  let!(:project1) { projects.create!(name: 'project1', path: 'project1', project_namespace_id: nil, namespace_id: group.id, visibility_level: 20) }
  let!(:project2) { projects.create!(name: 'project2', path: 'project2', project_namespace_id: project_namespace.id, namespace_id: group.id, visibility_level: 20) }
  let!(:project3) { projects.create!(name: 'project3', path: 'project3', project_namespace_id: nil, namespace_id: group.id, visibility_level: 20) }
  let!(:project4) { projects.create!(name: 'project4', path: 'project4', project_namespace_id: nil, namespace_id: group.id, visibility_level: 20) }

  describe '#up' do
    it 'schedules background migrations' do
      Sidekiq::Testing.fake! do
        freeze_time do
          described_class.new.up

          migration = described_class::MIGRATION

          expect(migration).to be_scheduled_delayed_migration(2.minutes, project1.id, project4.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq 1
        end
      end
    end

    context 'in batches' do
      before do
        stub_const('FixAndBackfillProjectNamespacesForProjectsWithDuplicateName::BATCH_SIZE', 2)
      end

      it 'schedules background migrations' do
        Sidekiq::Testing.fake! do
          freeze_time do
            described_class.new.up

            migration = described_class::MIGRATION

            expect(migration).to be_scheduled_delayed_migration(2.minutes, project1.id, project3.id)
            expect(migration).to be_scheduled_delayed_migration(4.minutes, project4.id, project4.id)
            expect(BackgroundMigrationWorker.jobs.size).to eq 2
          end
        end
      end
    end
  end
end
