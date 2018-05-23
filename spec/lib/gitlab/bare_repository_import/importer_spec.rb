require 'spec_helper'

describe Gitlab::BareRepositoryImport::Importer, repository: true do
  let!(:admin) { create(:admin) }
  let!(:base_dir) { Dir.mktmpdir + '/' }
  let(:bare_repository) { Gitlab::BareRepositoryImport::Repository.new(base_dir, File.join(base_dir, "#{project_path}.git")) }
  let(:gitlab_shell) { Gitlab::Shell.new }

  subject(:importer) { described_class.new(admin, bare_repository) }

  before do
    @rainbow = Rainbow.enabled
    Rainbow.enabled = false

    allow(described_class).to receive(:log)
  end

  after do
    FileUtils.rm_rf(base_dir)
    Rainbow.enabled = @rainbow
  end

  shared_examples 'importing a repository' do
    describe '.execute' do
      it 'creates a project for a repository in storage' do
        FileUtils.mkdir_p(File.join(base_dir, "#{project_path}.git"))
        fake_importer = double

        expect(described_class).to receive(:new).and_return(fake_importer)
        expect(fake_importer).to receive(:create_project_if_needed)

        described_class.execute(base_dir)
      end

      it 'skips wiki repos' do
        repo_dir = File.join(base_dir, 'the-group', 'the-project.wiki.git')
        FileUtils.mkdir_p(File.join(repo_dir))

        expect(described_class).to receive(:log).with(" * Skipping repo #{repo_dir}")
        expect(described_class).not_to receive(:new)

        described_class.execute(base_dir)
      end

      context 'without admin users' do
        let(:admin) { nil }

        it 'raises an error' do
          expect { described_class.execute(base_dir) }.to raise_error(Gitlab::BareRepositoryImport::Importer::NoAdminError)
        end
      end
    end

    describe '#create_project_if_needed' do
      it 'starts an import for a project that did not exist' do
        expect(importer).to receive(:create_project)

        importer.create_project_if_needed
      end

      it 'skips importing when the project already exists' do
        project = create(:project, path: 'a-project', namespace: existing_group)

        expect(importer).not_to receive(:create_project)
        expect(importer).to receive(:log).with(" * #{project.name} (#{project_path}) exists")

        importer.create_project_if_needed
      end

      it 'creates a project with the correct path in the database' do
        importer.create_project_if_needed

        expect(Project.find_by_full_path(project_path)).not_to be_nil
      end

      it 'does not schedule an import' do
        expect_any_instance_of(Project).not_to receive(:import_schedule)

        importer.create_project_if_needed
      end

      it 'creates the Git repo on disk with the proper symlink for hooks' do
        create_bare_repository("#{project_path}.git")

        importer.create_project_if_needed

        project = Project.find_by_full_path(project_path)
        repo_path = "#{project.disk_path}.git"
        hook_path = File.join(repo_path, 'hooks')

        expect(gitlab_shell.exists?(project.repository_storage, repo_path)).to be(true)
        expect(gitlab_shell.exists?(project.repository_storage, hook_path)).to be(true)

        full_hook_path = File.join(project.repository.path_to_repo, 'hooks')
        expect(File.readlink(full_hook_path)).to eq(Gitlab.config.gitlab_shell.hooks_path)
      end

      context 'hashed storage enabled' do
        it 'creates a project with the correct path in the database' do
          stub_application_setting(hashed_storage_enabled: true)

          importer.create_project_if_needed

          expect(Project.find_by_full_path(project_path)).not_to be_nil
        end
      end
    end
  end

  context 'with subgroups', :nested_groups do
    let(:project_path) { 'a-group/a-sub-group/a-project' }

    let(:existing_group) do
      group = create(:group, path: 'a-group')
      create(:group, path: 'a-sub-group', parent: group)
    end

    it_behaves_like 'importing a repository'
  end

  context 'without subgroups' do
    let(:project_path) { 'a-group/a-project' }
    let(:existing_group) { create(:group, path: 'a-group') }

    it_behaves_like 'importing a repository'
  end

  context 'without groups' do
    let(:project_path) { 'a-project' }

    it 'starts an import for a project that did not exist' do
      expect(importer).to receive(:create_project)

      importer.create_project_if_needed
    end

    it 'creates a project with the correct path in the database' do
      importer.create_project_if_needed

      expect(Project.find_by_full_path("#{admin.full_path}/#{project_path}")).not_to be_nil
    end

    it 'creates the Git repo in disk' do
      create_bare_repository("#{project_path}.git")

      importer.create_project_if_needed

      project = Project.find_by_full_path("#{admin.full_path}/#{project_path}")

      expect(gitlab_shell.exists?(project.repository_storage, project.disk_path + '.git')).to be(true)
      expect(gitlab_shell.exists?(project.repository_storage, project.disk_path + '.wiki.git')).to be(true)
    end

    it 'moves an existing project to the correct path' do
      # This is a quick way to get a valid repository instead of copying an
      # existing one. Since it's not persisted, the importer will try to
      # create the project.
      project = build(:project, :legacy_storage, :repository)
      original_commit_count = project.repository.commit_count

      legacy_path = Gitlab.config.repositories.storages[project.repository_storage].legacy_disk_path

      bare_repo = Gitlab::BareRepositoryImport::Repository.new(legacy_path, project.repository.path)
      gitlab_importer = described_class.new(admin, bare_repo)

      expect(gitlab_importer).to receive(:create_project).and_call_original

      new_project = gitlab_importer.create_project_if_needed

      expect(new_project.repository.commit_count).to eq(original_commit_count)
    end
  end

  context 'with Wiki' do
    let(:project_path) { 'a-group/a-project' }
    let(:existing_group) { create(:group, path: 'a-group') }

    it_behaves_like 'importing a repository'

    it 'creates the Wiki git repo in disk' do
      create_bare_repository("#{project_path}.git")
      create_bare_repository("#{project_path}.wiki.git")

      expect(Projects::CreateService).to receive(:new).with(admin, hash_including(skip_wiki: true,
                                                                                  import_type: 'bare_repository')).and_call_original

      importer.create_project_if_needed

      project = Project.find_by_full_path(project_path)

      expect(gitlab_shell.exists?(project.repository_storage, project.disk_path + '.wiki.git')).to be(true)
    end
  end

  context 'when subgroups are not available' do
    let(:project_path) { 'a-group/a-sub-group/a-project' }

    before do
      expect(Group).to receive(:supports_nested_groups?) { false }
    end

    describe '#create_project_if_needed' do
      it 'raises an error' do
        expect { importer.create_project_if_needed }.to raise_error('Nested groups are not supported on MySQL')
      end
    end
  end

  def create_bare_repository(project_path)
    repo_path = File.join(base_dir, project_path)
    Gitlab::Git::Repository.create(repo_path, bare: true)
  end
end
