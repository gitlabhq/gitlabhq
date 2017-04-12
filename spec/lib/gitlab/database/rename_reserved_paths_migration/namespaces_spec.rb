require 'spec_helper'

describe Gitlab::Database::RenameReservedPathsMigration::Namespaces, :truncate do
  let(:test_dir) { File.join(Rails.root, 'tmp', 'tests', 'rename_namespaces_test') }
  let(:uploads_dir) { File.join(test_dir, 'public', 'uploads') }
  let(:subject) do
    ActiveRecord::Migration.new.extend(
      Gitlab::Database::RenameReservedPathsMigration
    )
  end

  before do
    FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
    FileUtils.mkdir_p(uploads_dir)
    FileUtils.remove_dir(TestEnv.repos_path) if File.directory?(TestEnv.repos_path)
    allow(subject).to receive(:uploads_dir).and_return(uploads_dir)
    allow(subject).to receive(:say)
  end

  def migration_namespace(namespace)
    Gitlab::Database::RenameReservedPathsMigration::MigrationClasses::
      Namespace.find(namespace.id)
  end

  describe '#namespaces_for_paths' do
    context 'for wildcard namespaces' do
      it 'only returns child namespaces with the correct path' do
        _root_namespace = create(:namespace, path: 'the-path')
        _other_path = create(:namespace,
                             path: 'other',
                             parent: create(:namespace))
        namespace = create(:namespace,
                           path: 'the-path',
                           parent: create(:namespace))

        found_ids = subject.namespaces_for_paths(['the-path'], type: :wildcard).
                      pluck(:id)
        expect(found_ids).to contain_exactly(namespace.id)
      end
    end

    context 'for top level namespaces' do
      it 'only returns child namespaces with the correct path' do
        root_namespace = create(:namespace, path: 'the-path')
        _other_path = create(:namespace, path: 'other')
        _child_namespace = create(:namespace,
                           path: 'the-path',
                           parent: create(:namespace))

        found_ids = subject.namespaces_for_paths(['the-path'], type: :top_level).
                      pluck(:id)
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

  describe '#move_namespace_folders' do
    it 'moves a namespace with files' do
      source = File.join(uploads_dir, 'parent-group', 'sub-group')
      FileUtils.mkdir_p(source)
      destination = File.join(uploads_dir, 'parent-group', 'moved-group')
      FileUtils.touch(File.join(source, 'test.txt'))
      expected_file = File.join(destination, 'test.txt')

      subject.move_namespace_folders(uploads_dir, File.join('parent-group', 'sub-group'), File.join('parent-group', 'moved-group'))

      expect(File.exist?(expected_file)).to be(true)
    end

    it 'moves a parent namespace uploads' do
      source = File.join(uploads_dir, 'parent-group', 'sub-group')
      FileUtils.mkdir_p(source)
      destination = File.join(uploads_dir, 'moved-parent', 'sub-group')
      FileUtils.touch(File.join(source, 'test.txt'))
      expected_file = File.join(destination, 'test.txt')

      subject.move_namespace_folders(uploads_dir, 'parent-group', 'moved-parent')

      expect(File.exist?(expected_file)).to be(true)
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

  describe "#remove_last_ocurrence" do
    it "removes only the last occurance of a string" do
      input = "this/is/a-word-to-replace/namespace/with/a-word-to-replace"

      expect(subject.remove_last_occurrence(input, "a-word-to-replace"))
        .to eq("this/is/a-word-to-replace/namespace/with/")
    end
  end

  describe "#rename_namespace" do
    let(:namespace) { create(:namespace, path: 'the-path') }
    it "renames namespaces called the-path" do
      subject.rename_namespace(namespace)

      expect(namespace.reload.path).to eq("the-path0")
    end

    it "renames the route to the namespace" do
      subject.rename_namespace(namespace)

      expect(Namespace.find(namespace.id).full_path).to eq("the-path0")
    end

    it "renames the route for projects of the namespace" do
      project = create(:project, path: "project-path", namespace: namespace)

      subject.rename_namespace(namespace)

      expect(project.route.reload.path).to eq("the-path0/project-path")
    end

    it "moves the the repository for a project in the namespace" do
      create(:project, namespace: namespace, path: "the-path-project")
      expected_repo = File.join(TestEnv.repos_path, "the-path0", "the-path-project.git")

      subject.rename_namespace(namespace)

      expect(File.directory?(expected_repo)).to be(true)
    end

    it "moves the uploads for the namespace" do
      allow(subject).to receive(:move_namespace_folders).with(Settings.pages.path, "the-path", "the-path0")
      expect(subject).to receive(:move_namespace_folders).with(uploads_dir, "the-path", "the-path0")

      subject.rename_namespace(namespace)
    end

    it "moves the pages for the namespace" do
      allow(subject).to receive(:move_namespace_folders).with(uploads_dir, "the-path", "the-path0")
      expect(subject).to receive(:move_namespace_folders).with(Settings.pages.path, "the-path", "the-path0")

      subject.rename_namespace(namespace)
    end

    context "the-path namespace -> subgroup -> the-path0 project" do
      it "updates the route of the project correctly" do
        subgroup = create(:group, path: "subgroup", parent: namespace)
        project = create(:project, path: "the-path0", namespace: subgroup)

        subject.rename_namespace(namespace)

        expect(project.route.reload.path).to eq("the-path0/subgroup/the-path0")
      end
    end
  end

  describe '#rename_namespaces' do
    context 'top level namespaces' do
      let!(:namespace) { create(:namespace, path: 'the-path') }

      it 'should rename the namespace' do
        expect(subject).to receive(:rename_namespace).
                             with(migration_namespace(namespace))

        subject.rename_namespaces(['the-path'], type: :top_level)
      end
    end
  end
end
