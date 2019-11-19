# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

describe Gitlab::Shell do
  set(:project) { create(:project, :repository) }

  let(:repository) { project.repository }
  let(:gitlab_shell) { described_class.new }
  let(:popen_vars) { { 'GIT_TERMINAL_PROMPT' => ENV['GIT_TERMINAL_PROMPT'] } }
  let(:timeout) { Gitlab.config.gitlab_shell.git_timeout }
  let(:gitlab_authorized_keys) { double }

  before do
    allow(Project).to receive(:find).and_return(project)
  end

  it { is_expected.to respond_to :add_key }
  it { is_expected.to respond_to :remove_key }
  it { is_expected.to respond_to :create_repository }
  it { is_expected.to respond_to :remove_repository }
  it { is_expected.to respond_to :fork_repository }

  it { expect(gitlab_shell.url_to_repo('diaspora')).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + "diaspora.git") }

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

  describe '#add_key' do
    context 'when authorized_keys_enabled is true' do
      it 'calls Gitlab::AuthorizedKeys#add_key with id and key' do
        expect(Gitlab::AuthorizedKeys).to receive(:new).and_return(gitlab_authorized_keys)

        expect(gitlab_authorized_keys)
          .to receive(:add_key)
          .with('key-123', 'ssh-rsa foobar')

        gitlab_shell.add_key('key-123', 'ssh-rsa foobar')
      end
    end

    context 'when authorized_keys_enabled is false' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does nothing' do
        expect(Gitlab::AuthorizedKeys).not_to receive(:new)

        gitlab_shell.add_key('key-123', 'ssh-rsa foobar trailing garbage')
      end
    end

    context 'when authorized_keys_enabled is nil' do
      before do
        stub_application_setting(authorized_keys_enabled: nil)
      end

      it 'calls Gitlab::AuthorizedKeys#add_key with id and key' do
        expect(Gitlab::AuthorizedKeys).to receive(:new).and_return(gitlab_authorized_keys)

        expect(gitlab_authorized_keys)
          .to receive(:add_key)
          .with('key-123', 'ssh-rsa foobar')

        gitlab_shell.add_key('key-123', 'ssh-rsa foobar')
      end
    end
  end

  describe '#batch_add_keys' do
    let(:keys) { [double(shell_id: 'key-123', key: 'ssh-rsa foobar')] }

    context 'when authorized_keys_enabled is true' do
      it 'calls Gitlab::AuthorizedKeys#batch_add_keys with keys to be added' do
        expect(Gitlab::AuthorizedKeys).to receive(:new).and_return(gitlab_authorized_keys)

        expect(gitlab_authorized_keys)
          .to receive(:batch_add_keys)
          .with(keys)

        gitlab_shell.batch_add_keys(keys)
      end
    end

    context 'when authorized_keys_enabled is false' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does nothing' do
        expect(Gitlab::AuthorizedKeys).not_to receive(:new)

        gitlab_shell.batch_add_keys(keys)
      end
    end

    context 'when authorized_keys_enabled is nil' do
      before do
        stub_application_setting(authorized_keys_enabled: nil)
      end

      it 'calls Gitlab::AuthorizedKeys#batch_add_keys with keys to be added' do
        expect(Gitlab::AuthorizedKeys).to receive(:new).and_return(gitlab_authorized_keys)

        expect(gitlab_authorized_keys)
          .to receive(:batch_add_keys)
          .with(keys)

        gitlab_shell.batch_add_keys(keys)
      end
    end
  end

  describe '#remove_key' do
    context 'when authorized_keys_enabled is true' do
      it 'calls Gitlab::AuthorizedKeys#rm_key with the key to be removed' do
        expect(Gitlab::AuthorizedKeys).to receive(:new).and_return(gitlab_authorized_keys)
        expect(gitlab_authorized_keys).to receive(:rm_key).with('key-123')

        gitlab_shell.remove_key('key-123')
      end
    end

    context 'when authorized_keys_enabled is false' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does nothing' do
        expect(Gitlab::AuthorizedKeys).not_to receive(:new)

        gitlab_shell.remove_key('key-123')
      end
    end

    context 'when authorized_keys_enabled is nil' do
      before do
        stub_application_setting(authorized_keys_enabled: nil)
      end

      it 'calls Gitlab::AuthorizedKeys#rm_key with the key to be removed' do
        expect(Gitlab::AuthorizedKeys).to receive(:new).and_return(gitlab_authorized_keys)
        expect(gitlab_authorized_keys).to receive(:rm_key).with('key-123')

        gitlab_shell.remove_key('key-123')
      end
    end
  end

  describe '#remove_all_keys' do
    context 'when authorized_keys_enabled is true' do
      it 'calls Gitlab::AuthorizedKeys#clear' do
        expect(Gitlab::AuthorizedKeys).to receive(:new).and_return(gitlab_authorized_keys)
        expect(gitlab_authorized_keys).to receive(:clear)

        gitlab_shell.remove_all_keys
      end
    end

    context 'when authorized_keys_enabled is false' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does nothing' do
        expect(Gitlab::AuthorizedKeys).not_to receive(:new)

        gitlab_shell.remove_all_keys
      end
    end

    context 'when authorized_keys_enabled is nil' do
      before do
        stub_application_setting(authorized_keys_enabled: nil)
      end

      it 'calls Gitlab::AuthorizedKeys#clear' do
        expect(Gitlab::AuthorizedKeys).to receive(:new).and_return(gitlab_authorized_keys)
        expect(gitlab_authorized_keys).to receive(:clear)

        gitlab_shell.remove_all_keys
      end
    end
  end

  describe '#remove_keys_not_found_in_db' do
    context 'when keys are in the file that are not in the DB' do
      before do
        gitlab_shell.remove_all_keys
        gitlab_shell.add_key('key-1234', 'ssh-rsa ASDFASDF')
        gitlab_shell.add_key('key-9876', 'ssh-rsa ASDFASDF')
        @another_key = create(:key) # this one IS in the DB
      end

      it 'removes the keys' do
        expect(gitlab_shell).to receive(:remove_key).with('key-1234')
        expect(gitlab_shell).to receive(:remove_key).with('key-9876')
        expect(gitlab_shell).not_to receive(:remove_key).with("key-#{@another_key.id}")

        gitlab_shell.remove_keys_not_found_in_db
      end
    end

    context 'when keys there are duplicate keys in the file that are not in the DB' do
      before do
        gitlab_shell.remove_all_keys
        gitlab_shell.add_key('key-1234', 'ssh-rsa ASDFASDF')
        gitlab_shell.add_key('key-1234', 'ssh-rsa ASDFASDF')
      end

      it 'removes the keys' do
        expect(gitlab_shell).to receive(:remove_key).with('key-1234')

        gitlab_shell.remove_keys_not_found_in_db
      end
    end

    context 'when keys there are duplicate keys in the file that ARE in the DB' do
      before do
        gitlab_shell.remove_all_keys
        @key = create(:key)
        gitlab_shell.add_key(@key.shell_id, @key.key)
      end

      it 'does not remove the key' do
        expect(gitlab_shell).not_to receive(:remove_key).with("key-#{@key.id}")

        gitlab_shell.remove_keys_not_found_in_db
      end
    end

    unless ENV['CI'] # Skip in CI, it takes 1 minute
      context 'when the first batch can be skipped, but the next batch has keys that are not in the DB' do
        before do
          gitlab_shell.remove_all_keys
          100.times { |i| create(:key) } # first batch is all in the DB
          gitlab_shell.add_key('key-1234', 'ssh-rsa ASDFASDF')
        end

        it 'removes the keys not in the DB' do
          expect(gitlab_shell).to receive(:remove_key).with('key-1234')

          gitlab_shell.remove_keys_not_found_in_db
        end
      end
    end
  end

  describe 'projects commands' do
    let(:gitlab_shell_path) { File.expand_path('tmp/tests/gitlab-shell') }
    let(:projects_path) { File.join(gitlab_shell_path, 'bin/gitlab-projects') }
    let(:gitlab_shell_hooks_path) { File.join(gitlab_shell_path, 'hooks') }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:path).and_return(gitlab_shell_path)
      allow(Gitlab.config.gitlab_shell).to receive(:git_timeout).and_return(800)
    end

    describe '#create_repository' do
      let(:repository_storage) { 'default' }
      let(:repository_storage_path) do
        Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          Gitlab.config.repositories.storages[repository_storage].legacy_disk_path
        end
      end
      let(:repo_name) { 'project/path' }
      let(:created_path) { File.join(repository_storage_path, repo_name + '.git') }

      after do
        FileUtils.rm_rf(created_path)
      end

      it 'returns false when the command fails' do
        FileUtils.mkdir_p(File.dirname(created_path))
        # This file will block the creation of the repo's .git directory. That
        # should cause #create_repository to fail.
        FileUtils.touch(created_path)

        expect(gitlab_shell.create_repository(repository_storage, repo_name, repo_name)).to be_falsy
      end
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

    describe '#fork_repository' do
      let(:target_project) { create(:project) }

      subject do
        gitlab_shell.fork_repository(project, target_project)
      end

      it 'returns true when the command succeeds' do
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:fork_repository)
          .with(repository.raw_repository) { :gitaly_response_object }

        is_expected.to be_truthy
      end

      it 'return false when the command fails' do
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:fork_repository)
          .with(repository.raw_repository) { raise GRPC::BadStatus, 'bla' }

        is_expected.to be_falsy
      end
    end

    describe '#import_repository' do
      let(:import_url) { 'https://gitlab.com/gitlab-org/gitlab-foss.git' }

      context 'with gitaly' do
        it 'returns true when the command succeeds' do
          expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:import_repository).with(import_url)

          result = gitlab_shell.import_repository(project.repository_storage, project.disk_path, import_url, project.full_path)

          expect(result).to be_truthy
        end

        it 'raises an exception when the command fails' do
          expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:import_repository)
            .with(import_url) { raise GRPC::BadStatus, 'bla' }
          expect_any_instance_of(Gitlab::Shell::GitalyGitlabProjects).to receive(:output) { 'error'}

          expect do
            gitlab_shell.import_repository(project.repository_storage, project.disk_path, import_url, project.full_path)
          end.to raise_error(Gitlab::Shell::Error, "error")
        end
      end
    end
  end

  describe 'namespace actions' do
    subject { described_class.new }

    let(:storage) { Gitlab.config.repositories.storages.keys.first }

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
