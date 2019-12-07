# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BareRepositoryImport::Importer, :seed_helper do
  let!(:admin) { create(:admin) }
  let!(:base_dir) { Dir.mktmpdir + '/' }
  let(:bare_repository) { Gitlab::BareRepositoryImport::Repository.new(base_dir, File.join(base_dir, "#{project_path}.git")) }
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:source_project) { TEST_REPO_PATH }

  subject(:importer) { described_class.new(admin, bare_repository) }

  before do
    allow(described_class).to receive(:log)
  end

  after do
    FileUtils.rm_rf(base_dir)
    TestEnv.clean_test_path
    ensure_seeds
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
        expect_next_instance_of(Project) do |instance|
          expect(instance).not_to receive(:import_schedule)
        end

        importer.create_project_if_needed
      end

      it 'creates the Git repo on disk' do
        prepare_repository("#{project_path}.git", source_project)

        importer.create_project_if_needed

        project = Project.find_by_full_path(project_path)
        repo_path = "#{project.disk_path}.git"
        hook_path = File.join(repo_path, 'hooks')

        expect(gitlab_shell.repository_exists?(project.repository_storage, repo_path)).to be(true)
        expect(TestEnv.storage_dir_exists?(project.repository_storage, hook_path)).to be(true)
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

  context 'with subgroups' do
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
      prepare_repository("#{project_path}.git", source_project)

      importer.create_project_if_needed

      project = Project.find_by_full_path("#{admin.full_path}/#{project_path}")

      expect(gitlab_shell.repository_exists?(project.repository_storage, project.disk_path + '.git')).to be(true)
      expect(gitlab_shell.repository_exists?(project.repository_storage, project.disk_path + '.wiki.git')).to be(true)
    end

    context 'with a repository already on disk' do
      let!(:base_dir) { TestEnv.repos_path }
      # This is a quick way to get a valid repository instead of copying an
      # existing one. Since it's not persisted, the importer will try to
      # create the project.
      let(:project) { build(:project, :legacy_storage, :repository) }
      let(:project_path) { project.full_path }

      it 'moves an existing project to the correct path' do
        original_commit_count = project.repository.commit_count

        expect(importer).to receive(:create_project).and_call_original

        new_project = importer.create_project_if_needed

        expect(new_project.repository.commit_count).to eq(original_commit_count)
      end
    end
  end

  context 'with Wiki' do
    let(:project_path) { 'a-group/a-project' }
    let(:existing_group) { create(:group, path: 'a-group') }

    it_behaves_like 'importing a repository'

    it 'creates the Wiki git repo in disk' do
      prepare_repository("#{project_path}.git", source_project)
      prepare_repository("#{project_path}.wiki.git", source_project)

      expect(Projects::CreateService).to receive(:new).with(admin, hash_including(skip_wiki: true,
                                                                                  import_type: 'bare_repository')).and_call_original

      importer.create_project_if_needed

      project = Project.find_by_full_path(project_path)

      expect(gitlab_shell.repository_exists?(project.repository_storage, project.disk_path + '.wiki.git')).to be(true)
    end
  end

  def prepare_repository(project_path, source_project)
    repo_path = File.join(base_dir, project_path)

    return create_bare_repository(repo_path) unless source_project

    cmd = %W(#{Gitlab.config.git.bin_path} clone --bare #{source_project} #{repo_path})

    system(git_env, *cmd, chdir: SEED_STORAGE_PATH, out: '/dev/null', err: '/dev/null')
  end
end
