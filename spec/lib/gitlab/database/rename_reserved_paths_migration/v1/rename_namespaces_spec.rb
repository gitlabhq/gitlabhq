# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::RenameReservedPathsMigration::V1::RenameNamespaces, :delete do
  let(:migration) { FakeRenameReservedPathMigrationV1.new }
  let(:subject) { described_class.new(['the-path'], migration) }
  let(:namespace) { create(:group, name: 'the-path') }

  before do
    allow(migration).to receive(:say)
    TestEnv.clean_test_path
  end

  def migration_namespace(namespace)
    Gitlab::Database::RenameReservedPathsMigration::V1::MigrationClasses::
      Namespace.find(namespace.id)
  end

  describe '#namespaces_for_paths' do
    context 'nested namespaces' do
      let(:subject) { described_class.new(['parent/the-Path'], migration) }

      it 'includes the namespace' do
        parent = create(:group, path: 'parent')
        child = create(:group, path: 'the-path', parent: parent)

        found_ids = subject.namespaces_for_paths(type: :child)
                      .map(&:id)

        expect(found_ids).to contain_exactly(child.id)
      end
    end

    context 'for child namespaces' do
      it 'only returns child namespaces with the correct path' do
        _root_namespace = create(:group, path: 'THE-path')
        _other_path = create(:group,
                             path: 'other',
                             parent: create(:group))
        namespace = create(:group,
                           path: 'the-path',
                           parent: create(:group))

        found_ids = subject.namespaces_for_paths(type: :child)
                      .map(&:id)

        expect(found_ids).to contain_exactly(namespace.id)
      end

      it 'has no namespaces that look the same' do
        _root_namespace = create(:group, path: 'THE-path')
        _similar_path = create(:group,
                             path: 'not-really-the-path',
                             parent: create(:group))
        namespace = create(:group,
                           path: 'the-path',
                           parent: create(:group))

        found_ids = subject.namespaces_for_paths(type: :child)
                      .map(&:id)

        expect(found_ids).to contain_exactly(namespace.id)
      end
    end

    context 'for top levelnamespaces' do
      it 'only returns child namespaces with the correct path' do
        root_namespace = create(:group, path: 'the-path')
        _other_path = create(:group, path: 'other')
        _child_namespace = create(:group,
                                  path: 'the-path',
                                  parent: create(:group))

        found_ids = subject.namespaces_for_paths(type: :top_level)
                      .map(&:id)

        expect(found_ids).to contain_exactly(root_namespace.id)
      end

      it 'has no namespaces that just look the same' do
        root_namespace = create(:group, path: 'the-path')
        _similar_path = create(:group, path: 'not-really-the-path')
        _child_namespace = create(:group,
                                  path: 'the-path',
                                  parent: create(:group))

        found_ids = subject.namespaces_for_paths(type: :top_level)
                      .map(&:id)

        expect(found_ids).to contain_exactly(root_namespace.id)
      end
    end
  end

  describe '#move_repositories' do
    let(:namespace) { create(:group, name: 'hello-group') }

    it 'moves a project for a namespace' do
      create(:project, :repository, :legacy_storage, namespace: namespace, path: 'hello-project')
      expected_path = File.join(TestEnv.repos_path, 'bye-group', 'hello-project.git')

      subject.move_repositories(namespace, 'hello-group', 'bye-group')

      expect(File.directory?(expected_path)).to be(true)
    end

    it 'moves a namespace in a subdirectory correctly' do
      child_namespace = create(:group, name: 'sub-group', parent: namespace)
      create(:project, :repository, :legacy_storage, namespace: child_namespace, path: 'hello-project')

      expected_path = File.join(TestEnv.repos_path, 'hello-group', 'renamed-sub-group', 'hello-project.git')

      subject.move_repositories(child_namespace, 'hello-group/sub-group', 'hello-group/renamed-sub-group')

      expect(File.directory?(expected_path)).to be(true)
    end

    it 'moves a parent namespace with subdirectories' do
      child_namespace = create(:group, name: 'sub-group', parent: namespace)
      create(:project, :repository, :legacy_storage, namespace: child_namespace, path: 'hello-project')
      expected_path = File.join(TestEnv.repos_path, 'renamed-group', 'sub-group', 'hello-project.git')

      subject.move_repositories(child_namespace, 'hello-group', 'renamed-group')

      expect(File.directory?(expected_path)).to be(true)
    end
  end

  describe "#child_ids_for_parent" do
    it "collects child ids for all levels" do
      parent = create(:group)
      first_child = create(:group, parent: parent)
      second_child = create(:group, parent: parent)
      third_child = create(:group, parent: second_child)
      all_ids = [parent.id, first_child.id, second_child.id, third_child.id]

      collected_ids = subject.child_ids_for_parent(parent, ids: [parent.id])

      expect(collected_ids).to contain_exactly(*all_ids)
    end
  end

  describe "#rename_namespace" do
    it 'renames paths & routes for the namespace' do
      expect(subject).to receive(:rename_path_for_routable)
                           .with(namespace)
                           .and_call_original

      subject.rename_namespace(namespace)

      expect(namespace.reload.path).to eq('the-path0')
    end

    it 'tracks the rename' do
      expect(subject).to receive(:track_rename)
                           .with('namespace', 'the-path', 'the-path0')

      subject.rename_namespace(namespace)
    end

    it 'renames things related to the namespace' do
      expect(subject).to receive(:rename_namespace_dependencies)
                           .with(namespace, 'the-path', 'the-path0')

      subject.rename_namespace(namespace)
    end
  end

  describe '#rename_namespace_dependencies' do
    it "moves the repository for a project in the namespace" do
      create(:project, :repository, :legacy_storage, namespace: namespace, path: "the-path-project")
      expected_repo = File.join(TestEnv.repos_path, "the-path0", "the-path-project.git")

      subject.rename_namespace_dependencies(namespace, 'the-path', 'the-path0')

      expect(File.directory?(expected_repo)).to be(true)
    end

    it "moves the uploads for the namespace" do
      expect(subject).to receive(:move_uploads).with("the-path", "the-path0")

      subject.rename_namespace_dependencies(namespace, 'the-path', 'the-path0')
    end

    it "moves the pages for the namespace" do
      expect(subject).to receive(:move_pages).with("the-path", "the-path0")

      subject.rename_namespace_dependencies(namespace, 'the-path', 'the-path0')
    end

    it 'invalidates the markdown cache of related projects' do
      project = create(:project, :legacy_storage, namespace: namespace, path: "the-path-project")

      expect(subject).to receive(:remove_cached_html_for_projects).with([project.id])

      subject.rename_namespace_dependencies(namespace, 'the-path', 'the-path0')
    end

    it "doesn't rename users for other namespaces" do
      expect(subject).not_to receive(:rename_user)

      subject.rename_namespace_dependencies(namespace, 'the-path', 'the-path0')
    end

    it 'renames the username of a namespace for a user' do
      user = create(:user, username: 'the-path')

      expect(subject).to receive(:rename_user).with('the-path', 'the-path0')

      subject.rename_namespace_dependencies(user.namespace, 'the-path', 'the-path0')
    end
  end

  describe '#rename_user' do
    it 'renames a username' do
      subject = described_class.new([], migration)
      user = create(:user, username: 'broken')

      subject.rename_user('broken', 'broken0')

      expect(user.reload.username).to eq('broken0')
    end
  end

  describe '#rename_namespaces' do
    let!(:top_level_namespace) { create(:group, path: 'the-path') }
    let!(:child_namespace) do
      create(:group, path: 'the-path', parent: create(:group))
    end

    it 'renames top level namespaces the namespace' do
      expect(subject).to receive(:rename_namespace)
                           .with(migration_namespace(top_level_namespace))

      subject.rename_namespaces(type: :top_level)
    end

    it 'renames child namespaces' do
      expect(subject).to receive(:rename_namespace)
                           .with(migration_namespace(child_namespace))

      subject.rename_namespaces(type: :child)
    end
  end

  describe '#revert_renames', :redis do
    it 'renames the routes back to the previous values' do
      project = create(:project, :legacy_storage, :repository, path: 'a-project', namespace: namespace)
      subject.rename_namespace(namespace)

      expect(subject).to receive(:perform_rename)
                           .with(
                             kind_of(Gitlab::Database::RenameReservedPathsMigration::V1::MigrationClasses::Namespace),
                             'the-path0',
                             'the-path'
                           ).and_call_original

      subject.revert_renames

      expect(namespace.reload.path).to eq('the-path')
      expect(namespace.reload.route.path).to eq('the-path')
      expect(project.reload.route.path).to eq('the-path/a-project')
    end

    it 'moves the repositories back to their original place' do
      project = create(:project, :repository, :legacy_storage, path: 'a-project', namespace: namespace)
      project.create_repository
      subject.rename_namespace(namespace)

      expected_path = File.join(TestEnv.repos_path, 'the-path', 'a-project.git')

      expect(subject).to receive(:rename_namespace_dependencies)
                           .with(
                             kind_of(Gitlab::Database::RenameReservedPathsMigration::V1::MigrationClasses::Namespace),
                             'the-path0',
                             'the-path'
                           ).and_call_original

      subject.revert_renames

      expect(File.directory?(expected_path)).to be_truthy
    end

    it "doesn't break when the namespace was renamed" do
      subject.rename_namespace(namespace)
      namespace.update!(path: 'renamed-afterwards')

      expect { subject.revert_renames }.not_to raise_error
    end
  end
end
