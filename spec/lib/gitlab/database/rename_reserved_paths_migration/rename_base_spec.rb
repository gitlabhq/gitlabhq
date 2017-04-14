require 'spec_helper'

describe Gitlab::Database::RenameReservedPathsMigration::RenameBase do
  let(:migration) { FakeRenameReservedPathMigration.new }
  let(:subject) { described_class.new(['the-path'], migration) }

  before do
    allow(migration).to receive(:say)
  end

  def migration_namespace(namespace)
    Gitlab::Database::RenameReservedPathsMigration::MigrationClasses::
      Namespace.find(namespace.id)
  end

  def migration_project(project)
    Gitlab::Database::RenameReservedPathsMigration::MigrationClasses::
      Project.find(project.id)
  end

  describe "#remove_last_ocurrence" do
    it "removes only the last occurance of a string" do
      input = "this/is/a-word-to-replace/namespace/with/a-word-to-replace"

      expect(subject.remove_last_occurrence(input, "a-word-to-replace"))
        .to eq("this/is/a-word-to-replace/namespace/with/")
    end
  end

  describe '#rename_path_for_routable' do
    context 'for namespaces' do
      let(:namespace) { create(:namespace, path: 'the-path') }
      it "renames namespaces called the-path" do
        subject.rename_path_for_routable(migration_namespace(namespace))

        expect(namespace.reload.path).to eq("the-path0")
      end

      it "renames the route to the namespace" do
        subject.rename_path_for_routable(migration_namespace(namespace))

        expect(Namespace.find(namespace.id).full_path).to eq("the-path0")
      end

      it "renames the route for projects of the namespace" do
        project = create(:project, path: "project-path", namespace: namespace)

        subject.rename_path_for_routable(migration_namespace(namespace))

        expect(project.route.reload.path).to eq("the-path0/project-path")
      end

      it 'returns the old & the new path' do
        old_path, new_path = subject.rename_path_for_routable(migration_namespace(namespace))

        expect(old_path).to eq('the-path')
        expect(new_path).to eq('the-path0')
      end

      context "the-path namespace -> subgroup -> the-path0 project" do
        it "updates the route of the project correctly" do
          subgroup = create(:group, path: "subgroup", parent: namespace)
          project = create(:project, path: "the-path0", namespace: subgroup)

          subject.rename_path_for_routable(migration_namespace(namespace))

          expect(project.route.reload.path).to eq("the-path0/subgroup/the-path0")
        end
      end
    end

    context 'for projects' do
      let(:parent) { create(:namespace, path: 'the-parent') }
      let(:project) { create(:empty_project, path: 'the-path', namespace: parent) }

      it 'renames the project called `the-path`' do
        subject.rename_path_for_routable(migration_project(project))

        expect(project.reload.path).to eq('the-path0')
      end

      it 'renames the route for the project' do
        subject.rename_path_for_routable(project)

        expect(project.reload.route.path).to eq('the-parent/the-path0')
      end

      it 'returns the old & new path' do
        old_path, new_path = subject.rename_path_for_routable(migration_project(project))

        expect(old_path).to eq('the-parent/the-path')
        expect(new_path).to eq('the-parent/the-path0')
      end
    end
  end

  describe '#move_pages' do
    it 'moves the pages directory' do
      expect(subject).to receive(:move_folders)
                           .with(TestEnv.pages_path, 'old-path', 'new-path')

      subject.move_pages('old-path', 'new-path')
    end
  end

  describe "#move_uploads" do
    let(:test_dir) { File.join(Rails.root, 'tmp', 'tests', 'rename_reserved_paths') }
    let(:uploads_dir) { File.join(test_dir, 'public', 'uploads') }

    it 'moves subdirectories in the uploads folder' do
      expect(subject).to receive(:uploads_dir).and_return(uploads_dir)
      expect(subject).to receive(:move_folders).with(uploads_dir, 'old_path', 'new_path')

      subject.move_uploads('old_path', 'new_path')
    end

    it "doesn't move uploads when they are stored in object storage" do
      expect(subject).to receive(:file_storage?).and_return(false)
      expect(subject).not_to receive(:move_folders)

      subject.move_uploads('old_path', 'new_path')
    end
  end

  describe '#move_folders' do
    let(:test_dir) { File.join(Rails.root, 'tmp', 'tests', 'rename_reserved_paths') }
    let(:uploads_dir) { File.join(test_dir, 'public', 'uploads') }

    before do
      FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
      FileUtils.mkdir_p(uploads_dir)
      allow(subject).to receive(:uploads_dir).and_return(uploads_dir)
    end

    it 'moves a folder with files' do
      source = File.join(uploads_dir, 'parent-group', 'sub-group')
      FileUtils.mkdir_p(source)
      destination = File.join(uploads_dir, 'parent-group', 'moved-group')
      FileUtils.touch(File.join(source, 'test.txt'))
      expected_file = File.join(destination, 'test.txt')

      subject.move_folders(uploads_dir, File.join('parent-group', 'sub-group'), File.join('parent-group', 'moved-group'))

      expect(File.exist?(expected_file)).to be(true)
    end
  end
end
