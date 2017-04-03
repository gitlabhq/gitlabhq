require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170403121055_rename_forbidden_root_namespaces.rb')

describe RenameForbiddenRootNamespaces, truncate: true do
  let(:migration) { described_class.new }
  let(:test_dir) { File.join(Rails.root, 'tmp', 'tests', 'rename_namespaces_test') }
  let(:uploads_dir) { File.join(test_dir, 'public', 'uploads') }
  let(:forbidden_namespace) do
    namespace = build(:namespace, path: 'api')
    namespace.save(validate: false)
    namespace
  end

  before do
    FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
    FileUtils.mkdir_p(uploads_dir)
    FileUtils.remove_dir(TestEnv.repos_path) if File.directory?(TestEnv.repos_path)
    allow(migration).to receive(:say)
    allow(migration).to receive(:uploads_dir).and_return(uploads_dir)
  end

  describe '#forbidden_namespaces_with_path' do
    before do
      forbidden_namespace
    end

    it 'includes namespaces called with path `api`' do
      expect(migration.forbidden_namespaces_with_path('api').map(&:id)).to include(forbidden_namespace.id)
    end
  end

  describe '#up' do
    before do
      forbidden_namespace
    end

    it 'renames namespaces called api' do
      migration.up

      expect(forbidden_namespace.reload.path).to eq('api0')
    end

    it 'renames the route to the namespace' do
      migration.up

      expect(forbidden_namespace.reload.full_path).to eq('api0')
    end

    it 'renames the route for projects of the namespace' do
      project = create(:project, path: 'project-path', namespace: forbidden_namespace)

      migration.up

      expect(project.route.reload.path).to eq('api0/project-path')
    end

    it 'moves the the repository for a project in the namespace' do
      create(:project, namespace: forbidden_namespace, path: 'api-project')
      expected_repo = File.join(TestEnv.repos_path, 'api0', 'api-project.git')

      migration.up

      expect(File.directory?(expected_repo)).to be(true)
    end

    it 'moves the uploads for the namespace' do
      allow(migration).to receive(:move_namespace_folders).with(Settings.pages.path, 'api', 'api0')
      expect(migration).to receive(:move_namespace_folders).with(uploads_dir, 'api', 'api0')

      migration.up
    end

    it 'moves the pages for the namespace' do
      allow(migration).to receive(:move_namespace_folders).with(uploads_dir, 'api', 'api0')
      expect(migration).to receive(:move_namespace_folders).with(Settings.pages.path, 'api', 'api0')

      migration.up
    end

    it 'clears the markdown cache for projects in the forbidden namespace' do
      project = create(:project, namespace: forbidden_namespace)
      scopes = { 'Project' => { id: [project.id] },
                 'Issue' => { project_id: [project.id] },
                 'MergeRequest' => { target_project_id: [project.id] },
                 'Note' => { project_id: [project.id] } }

      expect(ClearDatabaseCacheWorker).to receive(:perform_async).with(scopes)

      migration.up
    end

    context 'forbidden namespace -> subgroup -> api0 project' do
      it 'updates the route of the project correctly' do
        subgroup = create(:group, path: 'subgroup', parent: forbidden_namespace)
        project = create(:project, path: 'api0', namespace: subgroup)

        migration.up

        expect(project.route.reload.path).to eq('api0/subgroup/api0')
      end
    end

    context 'for a sub-namespace' do
      before do
        forbidden_namespace.parent = create(:namespace, path: 'parent')
        forbidden_namespace.save(validate: false)
      end

      it "doesn't rename child-namespace paths" do
        migration.up

        expect(forbidden_namespace.reload.full_path).to eq('parent/api')
      end
    end
  end

  describe '#move_repositories' do
    let(:namespace) { create(:group, name: 'hello-group') }
    it 'moves a project for a namespace' do
      create(:project, namespace: namespace, path: 'hello-project')
      expected_path = File.join(TestEnv.repos_path, 'bye-group', 'hello-project.git')

      migration.move_repositories(namespace, 'hello-group', 'bye-group')

      expect(File.directory?(expected_path)).to be(true)
    end

    it 'moves a namespace in a subdirectory correctly' do
      child_namespace = create(:group, name: 'sub-group', parent: namespace)
      create(:project, namespace: child_namespace, path: 'hello-project')

      expected_path = File.join(TestEnv.repos_path, 'hello-group', 'renamed-sub-group', 'hello-project.git')

      migration.move_repositories(child_namespace, 'hello-group/sub-group', 'hello-group/renamed-sub-group')

      expect(File.directory?(expected_path)).to be(true)
    end

    it 'moves a parent namespace with subdirectories' do
      child_namespace = create(:group, name: 'sub-group', parent: namespace)
      create(:project, namespace: child_namespace, path: 'hello-project')
      expected_path = File.join(TestEnv.repos_path, 'renamed-group', 'sub-group', 'hello-project.git')

      migration.move_repositories(child_namespace, 'hello-group', 'renamed-group')

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

      migration.move_namespace_folders(uploads_dir, File.join('parent-group', 'sub-group'), File.join('parent-group', 'moved-group'))

      expect(File.exist?(expected_file)).to be(true)
    end

    it 'moves a parent namespace uploads' do
      source = File.join(uploads_dir, 'parent-group', 'sub-group')
      FileUtils.mkdir_p(source)
      destination = File.join(uploads_dir, 'moved-parent', 'sub-group')
      FileUtils.touch(File.join(source, 'test.txt'))
      expected_file = File.join(destination, 'test.txt')

      migration.move_namespace_folders(uploads_dir, 'parent-group', 'moved-parent')

      expect(File.exist?(expected_file)).to be(true)
    end
  end

  describe '#child_ids_for_parent' do
    it 'collects child ids for all levels' do
      parent = create(:namespace)
      first_child = create(:namespace, parent: parent)
      second_child = create(:namespace, parent: parent)
      third_child = create(:namespace, parent: second_child)
      all_ids = [parent.id, first_child.id, second_child.id, third_child.id]

      collected_ids = migration.child_ids_for_parent(parent, ids: [parent.id])

      expect(collected_ids).to contain_exactly(*all_ids)
    end
  end

  describe '#remove_last_ocurrence' do
    it 'removes only the last occurance of a string' do
      input = 'this/is/api/namespace/with/api'

      expect(migration.remove_last_occurrence(input, 'api')).to eq('this/is/api/namespace/with/')
    end
  end
end
