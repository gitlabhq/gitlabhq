# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillRootStorageStatisticsForkStorageSizes, schema: 20230616082958, feature_category: :consumables_cost_management do # rubocop:disable Layout/LineLength
  describe '#perform' do
    let(:namespaces_table) { table(:namespaces) }
    let(:root_storage_statistics_table) { table(:namespace_root_storage_statistics) }
    let(:projects_table) { table(:projects) }
    let(:project_statistics_table) { table(:project_statistics) }
    let(:fork_networks_table) { table(:fork_networks) }
    let(:fork_network_members_table) { table(:fork_network_members) }

    it 'updates the public_forks_storage_size' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      create_fork!(project, storage_size: 100)

      migrate

      expect(root_storage_statistics.reload.public_forks_storage_size).to eq(100)
    end

    it 'totals the size of public forks in the namespace' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      create_fork!(project, name: 'my fork', storage_size: 100)
      create_fork!(project, name: 'my other fork', storage_size: 100)

      migrate

      expect(root_storage_statistics.reload.public_forks_storage_size).to eq(200)
    end

    it 'updates the internal_forks_storage_size' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      create_fork!(project, storage_size: 250)

      migrate

      expect(root_storage_statistics.reload.internal_forks_storage_size).to eq(250)
    end

    it 'totals the size of internal forks in the namespace' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      create_fork!(project, name: 'my fork', storage_size: 300)
      create_fork!(project, name: 'my other fork', storage_size: 300)

      migrate

      expect(root_storage_statistics.reload.internal_forks_storage_size).to eq(600)
    end

    it 'updates the private_forks_storage_size' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      create_fork!(project, storage_size: 50)

      migrate

      expect(root_storage_statistics.reload.private_forks_storage_size).to eq(50)
    end

    it 'totals the size of private forks in the namespace' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      create_fork!(project, name: 'my fork', storage_size: 350)
      create_fork!(project, name: 'my other fork', storage_size: 400)

      migrate

      expect(root_storage_statistics.reload.private_forks_storage_size).to eq(750)
    end

    it 'counts only the size of forks' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, storage_size: 100,
        visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      create_fork!(project, name: 'my public fork', storage_size: 150,
        visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      create_fork!(project, name: 'my internal fork', storage_size: 250,
        visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      create_fork!(project, name: 'my private fork', storage_size: 350,
        visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      migrate

      root_storage_statistics.reload
      expect(root_storage_statistics.public_forks_storage_size).to eq(150)
      expect(root_storage_statistics.internal_forks_storage_size).to eq(250)
      expect(root_storage_statistics.private_forks_storage_size).to eq(350)
    end

    it 'sums forks for multiple namespaces' do
      namespace_a, root_storage_statistics_a = create_namespace!
      namespace_b, root_storage_statistics_b = create_namespace!
      project = create_project!(namespace: namespace_a)
      create_fork!(project, namespace: namespace_a, storage_size: 100)
      create_fork!(project, namespace: namespace_b, storage_size: 200)

      migrate

      expect(root_storage_statistics_a.reload.private_forks_storage_size).to eq(100)
      expect(root_storage_statistics_b.reload.private_forks_storage_size).to eq(200)
    end

    it 'counts the size of forks in subgroups' do
      group, root_storage_statistics = create_group!
      subgroup = create_group!(parent: group)
      project = create_project!(namespace: group, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      create_fork!(project, namespace: subgroup, name: 'my fork A',
        storage_size: 123, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      create_fork!(project, namespace: subgroup, name: 'my fork B',
        storage_size: 456, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      create_fork!(project, namespace: subgroup, name: 'my fork C',
        storage_size: 789, visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      migrate

      root_storage_statistics.reload
      expect(root_storage_statistics.public_forks_storage_size).to eq(123)
      expect(root_storage_statistics.internal_forks_storage_size).to eq(456)
      expect(root_storage_statistics.private_forks_storage_size).to eq(789)
    end

    it 'counts the size of forks in more nested subgroups' do
      root, root_storage_statistics = create_group!
      child = create_group!(parent: root)
      grand_child = create_group!(parent: child)
      great_grand_child = create_group!(parent: grand_child)
      project = create_project!(namespace: root, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      create_fork!(project, namespace: grand_child, name: 'my fork A',
        storage_size: 200, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      create_fork!(project, namespace: great_grand_child, name: 'my fork B',
        storage_size: 300, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      create_fork!(project, namespace: great_grand_child, name: 'my fork C',
        storage_size: 400, visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      migrate

      root_storage_statistics.reload
      expect(root_storage_statistics.public_forks_storage_size).to eq(200)
      expect(root_storage_statistics.internal_forks_storage_size).to eq(300)
      expect(root_storage_statistics.private_forks_storage_size).to eq(400)
    end

    it 'counts forks of forks' do
      group, root_storage_statistics = create_group!
      other_group, other_root_storage_statistics = create_group!
      project = create_project!(namespace: group)
      fork_a = create_fork!(project, namespace: group, storage_size: 100)
      fork_b = create_fork!(fork_a, name: 'my other fork', namespace: group, storage_size: 50)
      create_fork!(fork_b, namespace: other_group, storage_size: 27)

      migrate

      expect(root_storage_statistics.reload.private_forks_storage_size).to eq(150)
      expect(other_root_storage_statistics.reload.private_forks_storage_size).to eq(27)
    end

    it 'counts multiple forks of the same project' do
      group, root_storage_statistics = create_group!
      project = create_project!(namespace: group)
      create_fork!(project, storage_size: 200)
      create_fork!(project, name: 'my other fork', storage_size: 88)

      migrate

      expect(root_storage_statistics.reload.private_forks_storage_size).to eq(288)
    end

    it 'updates a namespace with no forks' do
      namespace, root_storage_statistics = create_namespace!
      create_project!(namespace: namespace)

      migrate

      root_storage_statistics.reload
      expect(root_storage_statistics.public_forks_storage_size).to eq(0)
      expect(root_storage_statistics.internal_forks_storage_size).to eq(0)
      expect(root_storage_statistics.private_forks_storage_size).to eq(0)
    end

    it 'skips the update if the public_forks_storage_size has already been set' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      create_fork!(project, storage_size: 200)
      root_storage_statistics.update!(public_forks_storage_size: 100)

      migrate

      root_storage_statistics.reload
      expect(root_storage_statistics.public_forks_storage_size).to eq(100)
    end

    it 'skips the update if the internal_forks_storage_size has already been set' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      create_fork!(project, storage_size: 200)
      root_storage_statistics.update!(internal_forks_storage_size: 100)

      migrate

      root_storage_statistics.reload
      expect(root_storage_statistics.internal_forks_storage_size).to eq(100)
    end

    it 'skips the update if the private_forks_storage_size has already been set' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace, visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      create_fork!(project, storage_size: 200)
      root_storage_statistics.update!(private_forks_storage_size: 100)

      migrate

      root_storage_statistics.reload
      expect(root_storage_statistics.private_forks_storage_size).to eq(100)
    end

    it 'skips the update if the namespace is not found' do
      namespace, root_storage_statistics = create_namespace!
      project = create_project!(namespace: namespace)
      create_fork!(project, storage_size: 100)
      allow(::ApplicationRecord.connection).to receive(:execute)
        .with("SELECT type FROM namespaces WHERE id = #{namespace.id}")
        .and_return([])

      migrate

      root_storage_statistics.reload
      expect(root_storage_statistics.public_forks_storage_size).to eq(0)
      expect(root_storage_statistics.internal_forks_storage_size).to eq(0)
      expect(root_storage_statistics.private_forks_storage_size).to eq(0)
    end
  end

  def create_namespace!(name: 'abc', path: 'abc')
    namespace = namespaces_table.create!(name: name, path: path)
    namespace.update!(traversal_ids: [namespace.id])
    root_storage_statistics = root_storage_statistics_table.create!(namespace_id: namespace.id)

    [namespace, root_storage_statistics]
  end

  def create_group!(name: 'abc', path: 'abc', parent: nil)
    parent_id = parent.try(:id)
    group = namespaces_table.create!(name: name, path: path, type: 'Group', parent_id: parent_id)

    if parent_id
      parent_traversal_ids = namespaces_table.find(parent_id).traversal_ids
      group.update!(traversal_ids: parent_traversal_ids + [group.id])
      group
    else
      group.update!(traversal_ids: [group.id])
      root_storage_statistics = root_storage_statistics_table.create!(namespace_id: group.id)
      [group, root_storage_statistics]
    end
  end

  def create_project!(
    namespace:, storage_size: 100, name: 'my project',
    visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    project_namespace = namespaces_table.create!(name: name, path: name)
    project = projects_table.create!(name: name, namespace_id: namespace.id, project_namespace_id: project_namespace.id,
      visibility_level: visibility_level)
    project_statistics_table.create!(project_id: project.id, namespace_id: project.namespace_id,
      storage_size: storage_size)

    project
  end

  def create_fork!(project, storage_size:, name: 'my fork', visibility_level: nil, namespace: nil)
    fork_namespace = namespace || namespaces_table.find(project.namespace_id)
    fork_visibility_level = visibility_level || project.visibility_level

    project_fork = create_project!(name: name, namespace: fork_namespace,
      visibility_level: fork_visibility_level, storage_size: storage_size)

    fork_network_id = if membership = fork_network_members_table.find_by(project_id: project.id)
                        membership.fork_network_id
                      else
                        fork_network = fork_networks_table.create!(root_project_id: project.id)
                        fork_network_members_table.create!(fork_network_id: fork_network.id, project_id: project.id)
                        fork_network.id
                      end

    fork_network_members_table.create!(fork_network_id: fork_network_id, project_id: project_fork.id,
      forked_from_project_id: project.id)

    project_fork
  end

  def migrate
    described_class.new(start_id: 1, end_id: root_storage_statistics_table.last.id,
      batch_table: 'namespace_root_storage_statistics',
      batch_column: 'namespace_id',
      sub_batch_size: 100, pause_ms: 0,
      connection: ApplicationRecord.connection).perform
  end
end
