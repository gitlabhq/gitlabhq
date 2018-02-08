require 'spec_helper'

describe Gitlab::Database::RenameReservedPathsMigration::V1::RenameProjects, :delete do
  let(:migration) { FakeRenameReservedPathMigrationV1.new }
  let(:subject) { described_class.new(['the-path'], migration) }
  let(:project) do
    create(:project,
           :legacy_storage,
           path: 'the-path',
           namespace: create(:namespace, path: 'known-parent' ))
  end

  before do
    allow(migration).to receive(:say)
    TestEnv.clean_test_path
  end

  describe '#projects_for_paths' do
    it 'searches using nested paths' do
      namespace = create(:namespace, path: 'hello')
      project = create(:project, :legacy_storage, path: 'THE-path', namespace: namespace)

      result_ids = described_class.new(['Hello/the-path'], migration)
                     .projects_for_paths.map(&:id)

      expect(result_ids).to contain_exactly(project.id)
    end

    it 'includes the correct projects' do
      project = create(:project, :legacy_storage, path: 'THE-path')
      _other_project = create(:project, :legacy_storage)

      result_ids = subject.projects_for_paths.map(&:id)

      expect(result_ids).to contain_exactly(project.id)
    end
  end

  describe '#rename_projects' do
    let!(:projects) { create_list(:project, 2, :legacy_storage, path: 'the-path') }

    it 'renames each project' do
      expect(subject).to receive(:rename_project).twice

      subject.rename_projects
    end

    it 'invalidates the markdown cache of related projects' do
      expect(subject).to receive(:remove_cached_html_for_projects)
                           .with(projects.map(&:id))

      subject.rename_projects
    end
  end

  describe '#rename_project' do
    it 'renames path & route for the project' do
      expect(subject).to receive(:rename_path_for_routable)
                           .with(project)
                           .and_call_original

      subject.rename_project(project)

      expect(project.reload.path).to eq('the-path0')
    end

    it 'tracks the rename' do
      expect(subject).to receive(:track_rename)
                           .with('project', 'known-parent/the-path', 'known-parent/the-path0')

      subject.rename_project(project)
    end

    it 'renames the folders for the project' do
      expect(subject).to receive(:move_project_folders).with(project, 'known-parent/the-path', 'known-parent/the-path0')

      subject.rename_project(project)
    end
  end

  describe '#move_project_folders' do
    it 'moves the wiki & the repo' do
      expect(subject).to receive(:move_repository)
                           .with(project, 'known-parent/the-path.wiki', 'known-parent/the-path0.wiki')
      expect(subject).to receive(:move_repository)
                           .with(project, 'known-parent/the-path', 'known-parent/the-path0')

      subject.move_project_folders(project, 'known-parent/the-path', 'known-parent/the-path0')
    end

    it 'does not move the repositories when hashed storage is enabled' do
      project.update!(storage_version: Project::HASHED_STORAGE_FEATURES[:repository])

      expect(subject).not_to receive(:move_repository)

      subject.move_project_folders(project, 'known-parent/the-path', 'known-parent/the-path0')
    end

    it 'moves uploads' do
      expect(subject).to receive(:move_uploads)
                           .with('known-parent/the-path', 'known-parent/the-path0')

      subject.move_project_folders(project, 'known-parent/the-path', 'known-parent/the-path0')
    end

    it 'does not move uploads when hashed storage is enabled for attachments' do
      project.update!(storage_version: Project::HASHED_STORAGE_FEATURES[:attachments])

      expect(subject).not_to receive(:move_uploads)

      subject.move_project_folders(project, 'known-parent/the-path', 'known-parent/the-path0')
    end

    it 'moves pages' do
      expect(subject).to receive(:move_pages)
                           .with('known-parent/the-path', 'known-parent/the-path0')

      subject.move_project_folders(project, 'known-parent/the-path', 'known-parent/the-path0')
    end
  end

  describe '#move_repository' do
    let(:known_parent) { create(:namespace, path: 'known-parent') }
    let(:project) { create(:project, :repository, :legacy_storage, path: 'the-path', namespace: known_parent) }

    it 'moves the repository for a project' do
      expected_path = File.join(TestEnv.repos_path, 'known-parent', 'new-repo.git')

      subject.move_repository(project, 'known-parent/the-path', 'known-parent/new-repo')

      expect(File.directory?(expected_path)).to be(true)
    end
  end

  describe '#revert_renames', :redis do
    it 'renames the routes back to the previous values' do
      subject.rename_project(project)

      expect(subject).to receive(:perform_rename)
                           .with(
                             kind_of(Gitlab::Database::RenameReservedPathsMigration::V1::MigrationClasses::Project),
                             'known-parent/the-path0',
                             'known-parent/the-path'
                           ).and_call_original

      subject.revert_renames

      expect(project.reload.path).to eq('the-path')
      expect(project.route.path).to eq('known-parent/the-path')
    end

    it 'moves the repositories back to their original place' do
      project.create_repository
      subject.rename_project(project)

      expected_path = File.join(TestEnv.repos_path, 'known-parent', 'the-path.git')

      expect(subject).to receive(:move_project_folders)
                           .with(
                             kind_of(Gitlab::Database::RenameReservedPathsMigration::V1::MigrationClasses::Project),
                             'known-parent/the-path0',
                             'known-parent/the-path'
                           ).and_call_original

      subject.revert_renames

      expect(File.directory?(expected_path)).to be_truthy
    end

    it "doesn't break when the project was renamed" do
      subject.rename_project(project)
      project.update_attributes!(path: 'renamed-afterwards')

      expect { subject.revert_renames }.not_to raise_error
    end
  end
end
