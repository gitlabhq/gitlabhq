# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleLinkLfsObjectsProjects, :migration, :sidekiq do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:fork_networks) { table(:fork_networks) }
  let(:fork_network_members) { table(:fork_network_members) }
  let(:lfs_objects) { table(:lfs_objects) }
  let(:lfs_objects_projects) { table(:lfs_objects_projects) }

  let(:namespace) { namespaces.create!(name: 'GitLab', path: 'gitlab') }

  let(:fork_network) { fork_networks.create!(root_project_id: source_project.id) }
  let(:another_fork_network) { fork_networks.create!(root_project_id: another_source_project.id) }

  let(:source_project) { projects.create!(namespace_id: namespace.id) }
  let(:another_source_project) { projects.create!(namespace_id: namespace.id) }
  let(:project) { projects.create!(namespace_id: namespace.id) }
  let(:another_project) { projects.create!(namespace_id: namespace.id) }

  let(:lfs_object) { lfs_objects.create!(oid: 'abc123', size: 100) }
  let(:another_lfs_object) { lfs_objects.create!(oid: 'def456', size: 200) }

  let!(:source_project_lop_1) do
    lfs_objects_projects.create!(
      lfs_object_id: lfs_object.id,
      project_id: source_project.id
    )
  end

  let!(:source_project_lop_2) do
    lfs_objects_projects.create!(
      lfs_object_id: another_lfs_object.id,
      project_id: source_project.id
    )
  end

  let!(:another_source_project_lop_1) do
    lfs_objects_projects.create!(
      lfs_object_id: lfs_object.id,
      project_id: another_source_project.id
    )
  end

  let!(:another_source_project_lop_2) do
    lfs_objects_projects.create!(
      lfs_object_id: another_lfs_object.id,
      project_id: another_source_project.id
    )
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    # Create links between projects
    fork_network_members.create!(fork_network_id: fork_network.id, project_id: source_project.id, forked_from_project_id: nil)
    fork_network_members.create!(fork_network_id: fork_network.id, project_id: project.id, forked_from_project_id: source_project.id)
    fork_network_members.create!(fork_network_id: another_fork_network.id, project_id: another_source_project.id, forked_from_project_id: nil)
    fork_network_members.create!(fork_network_id: another_fork_network.id, project_id: another_project.id, forked_from_project_id: another_fork_network.root_project_id)
  end

  it 'schedules background migration to link LFS objects' do
    Sidekiq::Testing.fake! do
      migrate!

      expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      expect(described_class::MIGRATION)
        .to be_scheduled_delayed_migration(2.minutes, source_project_lop_1.id, source_project_lop_2.id)
      expect(described_class::MIGRATION)
        .to be_scheduled_delayed_migration(4.minutes, another_source_project_lop_1.id, another_source_project_lop_2.id)
    end
  end
end
