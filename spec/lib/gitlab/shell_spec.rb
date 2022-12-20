# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe Gitlab::Shell do
  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository }
  let(:gitlab_shell) { described_class.new }

  before do
    described_class.instance_variable_set(:@secret_token, nil)
  end

  it { is_expected.to respond_to :remove_repository }

  describe '.secret_token' do
    let(:secret_file) { 'tmp/tests/.secret_shell_test' }
    let(:link_file) { 'tmp/tests/shell-secret-test/.gitlab_shell_secret' }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:secret_file).and_return(secret_file)
      allow(Gitlab.config.gitlab_shell).to receive(:path).and_return('tmp/tests/shell-secret-test')
      FileUtils.mkdir('tmp/tests/shell-secret-test')
    end

    after do
      FileUtils.rm_rf('tmp/tests/shell-secret-test')
      FileUtils.rm_rf(secret_file)
    end

    shared_examples 'creates and links the secret token file' do
      it 'creates and links the secret token file' do
        secret_token = described_class.secret_token

        expect(File.exist?(secret_file)).to be(true)
        expect(File.read(secret_file).chomp).to eq(secret_token)
        expect(File.symlink?(link_file)).to be(true)
        expect(File.readlink(link_file)).to eq(secret_file)
      end
    end

    describe 'memoized secret_token' do
      before do
        described_class.ensure_secret_token!
      end

      it_behaves_like 'creates and links the secret token file'
    end

    context 'when link_file is a broken symbolic link' do
      before do
        File.symlink('tmp/tests/non_existing_file', link_file)
        described_class.ensure_secret_token!
      end

      it_behaves_like 'creates and links the secret token file'
    end

    context 'when secret_file exists' do
      let(:secret_token) { 'secret-token' }

      before do
        File.write(secret_file, 'secret-token')
        described_class.ensure_secret_token!
      end

      it_behaves_like 'creates and links the secret token file'

      it 'reads the token from the existing file' do
        expect(described_class.secret_token).to eq(secret_token)
      end
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
        expect(project.repository.raw).to exist

        expect(gitlab_shell.remove_repository(project.repository_storage, project.disk_path)).to be(true)

        expect(project.repository.raw).not_to exist
      end
    end

    describe '#mv_repository' do
      let!(:project2) { create(:project, :repository) }

      it 'returns true when the command succeeds' do
        old_repo = project2.repository.raw
        new_path = "project/new_path"
        new_repo = Gitlab::Git::Repository.new(project2.repository_storage, "#{new_path}.git", nil, nil)

        expect(old_repo).to exist
        expect(new_repo).not_to exist

        expect(gitlab_shell.mv_repository(project2.repository_storage, project2.disk_path, new_path)).to be_truthy

        expect(old_repo).not_to exist
        expect(new_repo).to exist
      end

      it 'returns false when the command fails' do
        expect(gitlab_shell.mv_repository(project2.repository_storage, project2.disk_path, '')).to be_falsy
        expect(project2.repository.raw).to exist
      end
    end
  end

  describe 'namespace actions' do
    subject { described_class.new }

    let(:storage) { Gitlab.config.repositories.storages.each_key.first }

    describe '#add_namespace' do
      it 'creates a namespace' do
        Gitlab::GitalyClient::NamespaceService.allow do
          subject.add_namespace(storage, "mepmep")

          expect(Gitlab::GitalyClient::NamespaceService.new(storage).exists?("mepmep")).to be(true)
        end
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

          expect(Gitlab::GitalyClient::NamespaceService.new(storage).exists?("mepmep")).to be(false)
        end
      end
    end

    describe '#mv_namespace' do
      it 'renames the namespace' do
        Gitlab::GitalyClient::NamespaceService.allow do
          subject.add_namespace(storage, "mepmep")
          subject.mv_namespace(storage, "mepmep", "2mep")

          expect(Gitlab::GitalyClient::NamespaceService.new(storage).exists?("mepmep")).to be(false)
          expect(Gitlab::GitalyClient::NamespaceService.new(storage).exists?("2mep")).to be(true)
        end
      end
    end
  end
end
