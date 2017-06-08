require "spec_helper"
require Rails.root.join("db", "migrate", "20170316163800_rename_system_namespaces.rb")

describe RenameSystemNamespaces, truncate: true do
  let(:migration) { described_class.new }
  let(:test_dir) { File.join(Rails.root, "tmp", "tests", "rename_namespaces_test") }
  let(:uploads_dir) { File.join(test_dir, "public", "uploads") }
  let(:system_namespace) do
    namespace = build(:namespace, path: "system")
    namespace.save(validate: false)
    namespace
  end

  def save_invalid_routable(routable)
    routable.__send__(:prepare_route)
    routable.save(validate: false)
  end

  before do
    FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
    FileUtils.mkdir_p(uploads_dir)
    FileUtils.remove_dir(TestEnv.repos_path) if File.directory?(TestEnv.repos_path)
    allow(migration).to receive(:say)
    allow(migration).to receive(:uploads_dir).and_return(uploads_dir)
  end

  describe "#system_namespace" do
    it "only root namespaces called with path `system`" do
      system_namespace
      system_namespace_with_parent = build(:namespace, path: 'system', parent: create(:namespace))
      system_namespace_with_parent.save(validate: false)

      expect(migration.system_namespace.id).to eq(system_namespace.id)
    end
  end

  describe "#up" do
    before do
      system_namespace
    end

    it "doesn't break if there are no namespaces called system" do
      Namespace.delete_all

      migration.up
    end

    it "renames namespaces called system" do
      migration.up

      expect(system_namespace.reload.path).to eq("system0")
    end

    it "renames the route to the namespace" do
      migration.up

      expect(system_namespace.reload.full_path).to eq("system0")
    end

    it "renames the route for projects of the namespace" do
      project = build(:project, path: "project-path", namespace: system_namespace)
      save_invalid_routable(project)

      migration.up

      expect(project.route.reload.path).to eq("system0/project-path")
    end

    it "doesn't touch routes of namespaces that look like system" do
      namespace = create(:group, path: 'systemlookalike')
      project = create(:project, namespace: namespace, path: 'the-project')

      migration.up

      expect(project.route.reload.path).to eq('systemlookalike/the-project')
      expect(namespace.route.reload.path).to eq('systemlookalike')
    end

    it "moves the the repository for a project in the namespace" do
      project = build(:project, namespace: system_namespace, path: "system-project")
      save_invalid_routable(project)
      TestEnv.copy_repo(project)
      expected_repo = File.join(TestEnv.repos_path, "system0", "system-project.git")

      migration.up

      expect(File.directory?(expected_repo)).to be(true)
    end

    it "moves the uploads for the namespace" do
      allow(migration).to receive(:move_namespace_folders).with(Settings.pages.path, "system", "system0")
      expect(migration).to receive(:move_namespace_folders).with(uploads_dir, "system", "system0")

      migration.up
    end

    it "moves the pages for the namespace" do
      allow(migration).to receive(:move_namespace_folders).with(uploads_dir, "system", "system0")
      expect(migration).to receive(:move_namespace_folders).with(Settings.pages.path, "system", "system0")

      migration.up
    end

    describe "clears the markdown cache for projects in the system namespace" do
      let!(:project) do
        project = build(:project, namespace: system_namespace)
        save_invalid_routable(project)
        project
      end

      it 'removes description_html from projects' do
        migration.up

        expect(project.reload.description_html).to be_nil
      end

      it 'removes issue descriptions' do
        issue = create(:issue, project: project, description_html: 'Issue description')

        migration.up

        expect(issue.reload.description_html).to be_nil
      end

      it 'removes merge request descriptions' do
        merge_request = create(:merge_request,
                               source_project: project,
                               target_project: project,
                               description_html: 'MergeRequest description')

        migration.up

        expect(merge_request.reload.description_html).to be_nil
      end

      it 'removes note html' do
        note = create(:note,
                      project: project,
                      noteable: create(:issue, project: project),
                      note_html: 'note description')

        migration.up

        expect(note.reload.note_html).to be_nil
      end

      it 'removes milestone description' do
        milestone = create(:milestone,
                           project: project,
                           description_html: 'milestone description')

        migration.up

        expect(milestone.reload.description_html).to be_nil
      end
    end

    context "system namespace -> subgroup -> system0 project" do
      it "updates the route of the project correctly" do
        subgroup = build(:group, path: "subgroup", parent: system_namespace)
        save_invalid_routable(subgroup)
        project = build(:project, path: "system0", namespace: subgroup)
        save_invalid_routable(project)

        migration.up

        expect(project.route.reload.path).to eq("system0/subgroup/system0")
      end
    end
  end

  describe "#move_repositories" do
    let(:namespace) { create(:group, name: "hello-group") }
    it "moves a project for a namespace" do
      create(:project, namespace: namespace, path: "hello-project")
      expected_path = File.join(TestEnv.repos_path, "bye-group", "hello-project.git")

      migration.move_repositories(namespace, "hello-group", "bye-group")

      expect(File.directory?(expected_path)).to be(true)
    end

    it "moves a namespace in a subdirectory correctly" do
      child_namespace = create(:group, name: "sub-group", parent: namespace)
      create(:project, namespace: child_namespace, path: "hello-project")

      expected_path = File.join(TestEnv.repos_path, "hello-group", "renamed-sub-group", "hello-project.git")

      migration.move_repositories(child_namespace, "hello-group/sub-group", "hello-group/renamed-sub-group")

      expect(File.directory?(expected_path)).to be(true)
    end

    it "moves a parent namespace with subdirectories" do
      child_namespace = create(:group, name: "sub-group", parent: namespace)
      create(:project, namespace: child_namespace, path: "hello-project")
      expected_path = File.join(TestEnv.repos_path, "renamed-group", "sub-group", "hello-project.git")

      migration.move_repositories(child_namespace, "hello-group", "renamed-group")

      expect(File.directory?(expected_path)).to be(true)
    end
  end

  describe "#move_namespace_folders" do
    it "moves a namespace with files" do
      source = File.join(uploads_dir, "parent-group", "sub-group")
      FileUtils.mkdir_p(source)
      destination = File.join(uploads_dir, "parent-group", "moved-group")
      FileUtils.touch(File.join(source, "test.txt"))
      expected_file = File.join(destination, "test.txt")

      migration.move_namespace_folders(uploads_dir, File.join("parent-group", "sub-group"), File.join("parent-group", "moved-group"))

      expect(File.exist?(expected_file)).to be(true)
    end

    it "moves a parent namespace uploads" do
      source = File.join(uploads_dir, "parent-group", "sub-group")
      FileUtils.mkdir_p(source)
      destination = File.join(uploads_dir, "moved-parent", "sub-group")
      FileUtils.touch(File.join(source, "test.txt"))
      expected_file = File.join(destination, "test.txt")

      migration.move_namespace_folders(uploads_dir, "parent-group", "moved-parent")

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

      collected_ids = migration.child_ids_for_parent(parent, ids: [parent.id])

      expect(collected_ids).to contain_exactly(*all_ids)
    end
  end

  describe "#remove_last_ocurrence" do
    it "removes only the last occurance of a string" do
      input = "this/is/system/namespace/with/system"

      expect(migration.remove_last_occurrence(input, "system")).to eq("this/is/system/namespace/with/")
    end
  end
end
