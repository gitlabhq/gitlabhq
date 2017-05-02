require 'spec_helper'

describe Gitlab::Database::RenameReservedPathsMigration::V1::RenameNamespaces do
  let(:migration) { FakeRenameReservedPathMigrationV1.new }
  let(:subject) { described_class.new(['the-path'], migration) }

  before do
    allow(migration).to receive(:say)
  end

  def migration_namespace(namespace)
    Gitlab::Database::RenameReservedPathsMigration::V1::MigrationClasses::
      Namespace.find(namespace.id)
  end

  describe '#namespaces_for_paths' do
    context 'nested namespaces' do
      let(:subject) { described_class.new(['parent/the-Path'], migration) }

      it 'includes the namespace' do
        parent = create(:namespace, path: 'parent')
        child = create(:namespace, path: 'the-path', parent: parent)

        found_ids = subject.namespaces_for_paths(type: :child).
                      map(&:id)
        expect(found_ids).to contain_exactly(child.id)
      end
    end

    context 'for child namespaces' do
      it 'only returns child namespaces with the correct path' do
        _root_namespace = create(:namespace, path: 'THE-path')
        _other_path = create(:namespace,
                             path: 'other',
                             parent: create(:namespace))
        namespace = create(:namespace,
                           path: 'the-path',
                           parent: create(:namespace))

        found_ids = subject.namespaces_for_paths(type: :child).
                      map(&:id)
        expect(found_ids).to contain_exactly(namespace.id)
      end
    end

    context 'for top levelnamespaces' do
      it 'only returns child namespaces with the correct path' do
        root_namespace = create(:namespace, path: 'the-path')
        _other_path = create(:namespace, path: 'other')
        _child_namespace = create(:namespace,
                                  path: 'the-path',
                                  parent: create(:namespace))

        found_ids = subject.namespaces_for_paths(type: :top_level).
                      map(&:id)
        expect(found_ids).to contain_exactly(root_namespace.id)
      end
    end
  end

  describe '#move_repositories' do
    let(:namespace) { create(:group, name: 'hello-group') }
    it 'moves a project for a namespace' do
      create(:project, namespace: namespace, path: 'hello-project')
      expected_path = File.join(TestEnv.repos_path, 'bye-group', 'hello-project.git')

      subject.move_repositories(namespace, 'hello-group', 'bye-group')

      expect(File.directory?(expected_path)).to be(true)
    end

    it 'moves a namespace in a subdirectory correctly' do
      child_namespace = create(:group, name: 'sub-group', parent: namespace)
      create(:project, namespace: child_namespace, path: 'hello-project')

      expected_path = File.join(TestEnv.repos_path, 'hello-group', 'renamed-sub-group', 'hello-project.git')

      subject.move_repositories(child_namespace, 'hello-group/sub-group', 'hello-group/renamed-sub-group')

      expect(File.directory?(expected_path)).to be(true)
    end

    it 'moves a parent namespace with subdirectories' do
      child_namespace = create(:group, name: 'sub-group', parent: namespace)
      create(:project, namespace: child_namespace, path: 'hello-project')
      expected_path = File.join(TestEnv.repos_path, 'renamed-group', 'sub-group', 'hello-project.git')

      subject.move_repositories(child_namespace, 'hello-group', 'renamed-group')

      expect(File.directory?(expected_path)).to be(true)
    end
  end

  describe "#child_ids_for_parent" do
    it "collects child ids for all levels" do
      parent = create(:namespace)
      first_child = create(:namespace, parent: parent)
      second_child = create(:namespace, parent: parent)
      third_child = create(:namespace, parent: second_child)
      all_ids = [parent.id, first_child.id, second_child.id, third_child.id]

      collected_ids = subject.child_ids_for_parent(parent, ids: [parent.id])

      expect(collected_ids).to contain_exactly(*all_ids)
    end
  end

  describe "#rename_namespace" do
    let(:namespace) { create(:namespace, path: 'the-path') }

    it 'renames paths & routes for the namespace' do
      expect(subject).to receive(:rename_path_for_routable).
                           with(namespace).
                           and_call_original

      subject.rename_namespace(namespace)

      expect(namespace.reload.path).to eq('the-path0')
    end

    it "moves the the repository for a project in the namespace" do
      create(:project, namespace: namespace, path: "the-path-project")
      expected_repo = File.join(TestEnv.repos_path, "the-path0", "the-path-project.git")

      subject.rename_namespace(namespace)

      expect(File.directory?(expected_repo)).to be(true)
    end

    it "moves the uploads for the namespace" do
      expect(subject).to receive(:move_uploads).with("the-path", "the-path0")

      subject.rename_namespace(namespace)
    end

    it "moves the pages for the namespace" do
      expect(subject).to receive(:move_pages).with("the-path", "the-path0")

      subject.rename_namespace(namespace)
    end

    it 'invalidates the markdown cache of related projects' do
      project = create(:empty_project, namespace: namespace, path: "the-path-project")

      expect(subject).to receive(:remove_cached_html_for_projects).with([project.id])

      subject.rename_namespace(namespace)
    end
  end

  describe '#rename_namespaces' do
    let!(:top_level_namespace) { create(:namespace, path: 'the-path') }
    let!(:child_namespace) do
      create(:namespace, path: 'the-path', parent: create(:namespace))
    end

    it 'renames top level namespaces the namespace' do
      expect(subject).to receive(:rename_namespace).
                           with(migration_namespace(top_level_namespace))

      subject.rename_namespaces(type: :top_level)
    end

    it 'renames child namespaces' do
      expect(subject).to receive(:rename_namespace).
                           with(migration_namespace(child_namespace))

      subject.rename_namespaces(type: :child)
    end
  end
end
