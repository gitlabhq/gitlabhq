# frozen_string_literal: true

require 'spec_helper'
require_migration!('schedule_cleanup_orphaned_lfs_objects_projects')

RSpec.describe ScheduleCleanupOrphanedLfsObjectsProjects, schema: 20210511165250 do
  let(:lfs_objects_projects) { table(:lfs_objects_projects) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:lfs_objects) { table(:lfs_objects) }

  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace') }
  let(:project) { projects.create!(namespace_id: namespace.id) }
  let(:another_project) { projects.create!(namespace_id: namespace.id) }
  let(:lfs_object) { lfs_objects.create!(oid: 'abcdef', size: 1) }
  let(:another_lfs_object) { lfs_objects.create!(oid: '1abcde', size: 2) }

  describe '#up' do
    it 'schedules CleanupOrphanedLfsObjectsProjects background jobs' do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      lfs_objects_project1 = lfs_objects_projects.create!(project_id: project.id, lfs_object_id: lfs_object.id)
      lfs_objects_project2 = lfs_objects_projects.create!(project_id: another_project.id, lfs_object_id: lfs_object.id)
      lfs_objects_project3 = lfs_objects_projects.create!(project_id: project.id, lfs_object_id: another_lfs_object.id)
      lfs_objects_project4 = lfs_objects_projects.create!(project_id: another_project.id, lfs_object_id: another_lfs_object.id)

      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, lfs_objects_project1.id, lfs_objects_project2.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, lfs_objects_project3.id, lfs_objects_project4.id)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
