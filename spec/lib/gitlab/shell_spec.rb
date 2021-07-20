# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe Gitlab::Shell do
  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository }
  let(:gitlab_shell) { described_class.new }

  it { is_expected.to respond_to :remove_repository }

  describe 'memoized secret_token' do
    let(:secret_file) { 'tmp/tests/.secret_shell_test' }
    let(:link_file) { 'tmp/tests/shell-secret-test/.gitlab_shell_secret' }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:secret_file).and_return(secret_file)
      allow(Gitlab.config.gitlab_shell).to receive(:path).and_return('tmp/tests/shell-secret-test')
      FileUtils.mkdir('tmp/tests/shell-secret-test')
      described_class.ensure_secret_token!
    end

    after do
      FileUtils.rm_rf('tmp/tests/shell-secret-test')
      FileUtils.rm_rf(secret_file)
    end

    it 'creates and links the secret token file' do
      secret_token = described_class.secret_token

      expect(File.exist?(secret_file)).to be(true)
      expect(File.read(secret_file).chomp).to eq(secret_token)
      expect(File.symlink?(link_file)).to be(true)
      expect(File.readlink(link_file)).to eq(secret_file)
    end
  end

  describe 'projects commands' do
    let(:gitlab_shell_path) { File.expand_path('tmp/tests/gitlab-shell') }
    let(:projects_path) { File.join(gitlab_shell_path, 'bin/gitlab-projects') }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:path).and_return(gitlab_shell_path)
      allow(Gitlab.config.gitlab_shell).to receive(:git_timeout).and_return(800)
    end

    describe '#remove_repository' do
      let!(:project) { create(:project, :repository, :legacy_storage) }
      let(:disk_path) { "#{project.disk_path}.git" }

      it 'returns true when the command succeeds' do
        expect(TestEnv.storage_dir_exists?(project.repository_storage, disk_path)).to be(true)

        expect(gitlab_shell.remove_repository(project.repository_storage, project.disk_path)).to be(true)

        expect(TestEnv.storage_dir_exists?(project.repository_storage, disk_path)).to be(false)
      end

      it 'keeps the namespace directory' do
        gitlab_shell.remove_repository(project.repository_storage, project.disk_path)

        expect(TestEnv.storage_dir_exists?(project.repository_storage, disk_path)).to be(false)
        expect(TestEnv.storage_dir_exists?(project.repository_storage, project.disk_path.gsub(project.name, ''))).to be(true)
      end
    end

    describe '#mv_repository' do
      let!(:project2) { create(:project, :repository) }

      it 'returns true when the command succeeds' do
        old_path = project2.disk_path
        new_path = "project/new_path"

        expect(TestEnv.storage_dir_exists?(project2.repository_storage, "#{old_path}.git")).to be(true)
        expect(TestEnv.storage_dir_exists?(project2.repository_storage, "#{new_path}.git")).to be(false)

        expect(gitlab_shell.mv_repository(project2.repository_storage, old_path, new_path)).to be_truthy

        expect(TestEnv.storage_dir_exists?(project2.repository_storage, "#{old_path}.git")).to be(false)
        expect(TestEnv.storage_dir_exists?(project2.repository_storage, "#{new_path}.git")).to be(true)
      end

      it 'returns false when the command fails' do
        expect(gitlab_shell.mv_repository(project2.repository_storage, project2.disk_path, '')).to be_falsy
        expect(TestEnv.storage_dir_exists?(project2.repository_storage, "#{project2.disk_path}.git")).to be(true)
      end
    end
  end

  describe 'namespace actions' do
    subject { described_class.new }

    let(:storage) { Gitlab.config.repositories.storages.each_key.first }

    describe '#add_namespace' do
      it 'creates a namespace' do
        Gitlab::GitalyClient::NamespaceService.allow { subject.add_namespace(storage, "mepmep") }

        expect(TestEnv.storage_dir_exists?(storage, "mepmep")).to be(true)
      end
    end

    describe '#repository_exists?' do
      context 'when the repository does not exist' do
        it 'returns false' do
          expect(subject.repository_exists?(storage, "non-existing.git")).to be(false)
        end
      end

      context 'when the repository exists' do
        it 'returns true' do
          project = create(:project, :repository, :legacy_storage)

          expect(subject.repository_exists?(storage, project.repository.disk_path + ".git")).to be(true)
        end
      end
    end

    describe '#remove' do
      it 'removes the namespace' do
        Gitlab::GitalyClient::NamespaceService.allow do
          subject.add_namespace(storage, "mepmep")
          subject.rm_namespace(storage, "mepmep")
        end

        expect(TestEnv.storage_dir_exists?(storage, "mepmep")).to be(false)
      end
    end

    describe '#mv_namespace' do
      it 'renames the namespace' do
        Gitlab::GitalyClient::NamespaceService.allow do
          subject.add_namespace(storage, "mepmep")
          subject.mv_namespace(storage, "mepmep", "2mep")
        end

        expect(TestEnv.storage_dir_exists?(storage, "mepmep")).to be(false)
        expect(TestEnv.storage_dir_exists?(storage, "2mep")).to be(true)
      end
    end
  end
end
