# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::LinkLfsObjects, :migration, schema: 2020_02_10_062432 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:fork_networks) { table(:fork_networks) }
  let(:fork_network_members) { table(:fork_network_members) }
  let(:lfs_objects) { table(:lfs_objects) }
  let(:lfs_objects_projects) { table(:lfs_objects_projects) }
  let(:namespace) { namespaces.create(name: 'GitLab', path: 'gitlab') }
  let(:source_project) { projects.create(namespace_id: namespace.id) }
  let(:another_source_project) { projects.create(namespace_id: namespace.id) }
  let(:project) { projects.create(namespace_id: namespace.id) }
  let(:another_project) { projects.create(namespace_id: namespace.id) }
  let(:other_project) { projects.create(namespace_id: namespace.id) }
  let(:linked_project) { projects.create(namespace_id: namespace.id) }
  let(:fork_network) { fork_networks.create(root_project_id: source_project.id) }
  let(:another_fork_network) { fork_networks.create(root_project_id: another_source_project.id) }
  let(:lfs_object) { lfs_objects.create(oid: 'abc123', size: 100) }
  let(:another_lfs_object) { lfs_objects.create(oid: 'def456', size: 200) }

  before do
    # Create links between projects
    fork_network_members.create(fork_network_id: fork_network.id, project_id: source_project.id, forked_from_project_id: nil)

    [project, another_project, linked_project].each do |p|
      fork_network_members.create(
        fork_network_id: fork_network.id,
        project_id: p.id,
        forked_from_project_id: fork_network.root_project_id
      )
    end

    fork_network_members.create(fork_network_id: another_fork_network.id, project_id: another_source_project.id, forked_from_project_id: nil)
    fork_network_members.create(fork_network_id: another_fork_network.id, project_id: other_project.id, forked_from_project_id: another_fork_network.root_project_id)

    # Links LFS objects to some projects
    [source_project, another_source_project, linked_project].each do |p|
      lfs_objects_projects.create(lfs_object_id: lfs_object.id, project_id: p.id)
      lfs_objects_projects.create(lfs_object_id: another_lfs_object.id, project_id: p.id)
    end
  end

  it 'creates LfsObjectsProject records for forks within the specified range of project IDs' do
    expect { subject.perform(project.id, other_project.id) }.to change { lfs_objects_projects.count }.by(6)

    expect(lfs_object_ids_for(project)).to match_array(lfs_object_ids_for(source_project))
    expect(lfs_object_ids_for(another_project)).to match_array(lfs_object_ids_for(source_project))
    expect(lfs_object_ids_for(other_project)).to match_array(lfs_object_ids_for(another_source_project))

    expect { subject.perform(project.id, other_project.id) }.not_to change { lfs_objects_projects.count }
  end

  context 'when it is not necessary to create LfsObjectProject records' do
    it 'does not create LfsObjectProject records' do
      expect { subject.perform(linked_project.id, linked_project.id) }
        .not_to change { lfs_objects_projects.count }
    end
  end

  def lfs_object_ids_for(project)
    lfs_objects_projects.where(project_id: project.id).pluck(:lfs_object_id)
  end
end
