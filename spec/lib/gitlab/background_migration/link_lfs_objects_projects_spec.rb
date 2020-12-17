# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::LinkLfsObjectsProjects, :migration, schema: 2020_03_10_075115 do
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
  let(:partially_linked_project) { projects.create!(namespace_id: namespace.id) }
  let(:fully_linked_project) { projects.create!(namespace_id: namespace.id) }

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
    stub_const("#{described_class}::BATCH_SIZE", 2)

    # Create links between projects
    fork_network_members.create!(fork_network_id: fork_network.id, project_id: source_project.id, forked_from_project_id: nil)

    [project, partially_linked_project, fully_linked_project].each do |p|
      fork_network_members.create!(
        fork_network_id: fork_network.id,
        project_id: p.id,
        forked_from_project_id: fork_network.root_project_id
      )
    end

    fork_network_members.create!(fork_network_id: another_fork_network.id, project_id: another_source_project.id, forked_from_project_id: nil)
    fork_network_members.create!(fork_network_id: another_fork_network.id, project_id: another_project.id, forked_from_project_id: another_fork_network.root_project_id)

    # Links LFS objects to some projects
    lfs_objects_projects.create!(lfs_object_id: lfs_object.id, project_id: fully_linked_project.id)
    lfs_objects_projects.create!(lfs_object_id: another_lfs_object.id, project_id: fully_linked_project.id)
    lfs_objects_projects.create!(lfs_object_id: lfs_object.id, project_id: partially_linked_project.id)
  end

  context 'when there are LFS objects to be linked' do
    it 'creates LfsObjectsProject records for forks based on the specified range of LfsObjectProject id' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |logger|
        expect(logger).to receive(:info).exactly(4).times
      end

      expect { subject.perform(source_project_lop_1.id, another_source_project_lop_2.id) }.to change { lfs_objects_projects.count }.by(5)

      expect(lfs_object_ids_for(project)).to match_array(lfs_object_ids_for(source_project))
      expect(lfs_object_ids_for(another_project)).to match_array(lfs_object_ids_for(another_source_project))
      expect(lfs_object_ids_for(partially_linked_project)).to match_array(lfs_object_ids_for(source_project))

      expect { subject.perform(source_project_lop_1.id, another_source_project_lop_2.id) }.not_to change { lfs_objects_projects.count }
    end
  end

  context 'when there are no LFS objects to be linked' do
    before do
      # Links LFS objects to all projects
      projects.all.each do |p|
        lfs_objects_projects.create!(lfs_object_id: lfs_object.id, project_id: p.id)
        lfs_objects_projects.create!(lfs_object_id: another_lfs_object.id, project_id: p.id)
      end
    end

    it 'does not create LfsObjectProject records' do
      expect { subject.perform(source_project_lop_1.id, another_source_project_lop_2.id) }
        .not_to change { lfs_objects_projects.count }
    end
  end

  def lfs_object_ids_for(project)
    lfs_objects_projects.where(project_id: project.id).pluck(:lfs_object_id)
  end
end
