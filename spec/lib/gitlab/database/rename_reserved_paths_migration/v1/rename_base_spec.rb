# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::RenameReservedPathsMigration::V1::RenameBase, :delete do
  let(:migration) { FakeRenameReservedPathMigrationV1.new }
  let(:subject) { described_class.new(['the-path'], migration) }

  before do
    allow(migration).to receive(:say)
    TestEnv.clean_test_path
  end

  def migration_namespace(namespace)
    Gitlab::Database::RenameReservedPathsMigration::V1::MigrationClasses::
      Namespace.find(namespace.id)
  end

  def migration_project(project)
    Gitlab::Database::RenameReservedPathsMigration::V1::MigrationClasses::
      Project.find(project.id)
  end

  describe "#remove_last_occurrence" do
    it "removes only the last occurrence of a string" do
      input = "this/is/a-word-to-replace/namespace/with/a-word-to-replace"

      expect(subject.remove_last_occurrence(input, "a-word-to-replace"))
        .to eq("this/is/a-word-to-replace/namespace/with/")
    end
  end

  describe '#remove_cached_html_for_projects' do
    let(:project) { create(:project, description_html: 'Project description') }

    it 'removes description_html from projects' do
      subject.remove_cached_html_for_projects([project.id])

      expect(project.reload.description_html).to be_nil
    end

    it 'removes issue descriptions' do
      issue = create(:issue, project: project, description_html: 'Issue description')

      subject.remove_cached_html_for_projects([project.id])

      expect(issue.reload.description_html).to be_nil
    end

    it 'removes merge request descriptions' do
      merge_request = create(:merge_request,
                             source_project: project,
                             target_project: project,
                             description_html: 'MergeRequest description')

      subject.remove_cached_html_for_projects([project.id])

      expect(merge_request.reload.description_html).to be_nil
    end

    it 'removes note html' do
      note = create(:note,
                    project: project,
                    noteable: create(:issue, project: project),
                    note_html: 'note description')

      subject.remove_cached_html_for_projects([project.id])

      expect(note.reload.note_html).to be_nil
    end

    it 'removes milestone description' do
      milestone = create(:milestone,
                    project: project,
                    description_html: 'milestone description')

      subject.remove_cached_html_for_projects([project.id])

      expect(milestone.reload.description_html).to be_nil
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
        project = create(:project, :repository, path: "project-path", namespace: namespace)

        subject.rename_path_for_routable(migration_namespace(namespace))

        expect(project.route.reload.path).to eq("the-path0/project-path")
      end

      it 'returns the old & the new path' do
        old_path, new_path = subject.rename_path_for_routable(migration_namespace(namespace))

        expect(old_path).to eq('the-path')
        expect(new_path).to eq('the-path0')
      end

      it "doesn't rename routes that start with a similar name" do
        other_namespace = create(:namespace, path: 'the-path-but-not-really')
        project = create(:project, path: 'the-project', namespace: other_namespace)

        subject.rename_path_for_routable(migration_namespace(namespace))

        expect(project.route.reload.path).to eq('the-path-but-not-really/the-project')
      end

      context "the-path namespace -> subgroup -> the-path0 project" do
        it "updates the route of the project correctly" do
          subgroup = create(:group, path: "subgroup", parent: namespace)
          project = create(:project, :repository, path: "the-path0", namespace: subgroup)

          subject.rename_path_for_routable(migration_namespace(namespace))

          expect(project.route.reload.path).to eq("the-path0/subgroup/the-path0")
        end
      end
    end

    context 'for projects' do
      let(:parent) { create(:namespace, path: 'the-parent') }
      let(:project) { create(:project, path: 'the-path', namespace: parent) }

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

  describe '#perform_rename' do
    describe 'for namespaces' do
      let(:namespace) { create(:namespace, path: 'the-path') }

      it 'renames the path' do
        subject.perform_rename(migration_namespace(namespace), 'the-path', 'renamed')

        expect(namespace.reload.path).to eq('renamed')
      end

      it 'renames all the routes for the namespace' do
        child = create(:group, path: 'child', parent: namespace)
        project = create(:project, :repository, namespace: child, path: 'the-project')
        other_one = create(:namespace, path: 'the-path-is-similar')

        subject.perform_rename(migration_namespace(namespace), 'the-path', 'renamed')

        expect(namespace.reload.route.path).to eq('renamed')
        expect(child.reload.route.path).to eq('renamed/child')
        expect(project.reload.route.path).to eq('renamed/child/the-project')
        expect(other_one.reload.route.path).to eq('the-path-is-similar')
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

  describe '#track_rename', :redis do
    it 'tracks a rename in redis' do
      key = 'rename:FakeRenameReservedPathMigrationV1:namespace'

      subject.track_rename('namespace', 'path/to/namespace', 'path/to/renamed')

      old_path, new_path = [nil, nil]
      Gitlab::Redis::SharedState.with do |redis|
        rename_info = redis.lpop(key)
        old_path, new_path = JSON.parse(rename_info)
      end

      expect(old_path).to eq('path/to/namespace')
      expect(new_path).to eq('path/to/renamed')
    end
  end

  describe '#reverts_for_type', :redis do
    it 'yields for each tracked rename' do
      subject.track_rename('project', 'old_path', 'new_path')
      subject.track_rename('project', 'old_path2', 'new_path2')
      subject.track_rename('namespace', 'namespace_path', 'new_namespace_path')

      expect { |b| subject.reverts_for_type('project', &b) }
        .to yield_successive_args(%w(old_path2 new_path2), %w(old_path new_path))
      expect { |b| subject.reverts_for_type('namespace', &b) }
        .to yield_with_args('namespace_path', 'new_namespace_path')
    end

    it 'keeps the revert in redis if it failed' do
      subject.track_rename('project', 'old_path', 'new_path')

      subject.reverts_for_type('project') do
        raise 'whatever happens, keep going!'
      end

      key = 'rename:FakeRenameReservedPathMigrationV1:project'
      stored_renames = nil
      rename_count = 0
      Gitlab::Redis::SharedState.with do |redis|
        stored_renames = redis.lrange(key, 0, 1)
        rename_count = redis.llen(key)
      end

      expect(rename_count).to eq(1)
      expect(JSON.parse(stored_renames.first)).to eq(%w(old_path new_path))
    end
  end
end
