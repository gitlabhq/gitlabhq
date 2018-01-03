require 'spec_helper'
require 'stringio'

describe Gitlab::Shell do
  set(:project) { create(:project, :repository) }

  let(:gitlab_shell) { described_class.new }
  let(:popen_vars) { { 'GIT_TERMINAL_PROMPT' => ENV['GIT_TERMINAL_PROMPT'] } }
  let(:gitlab_projects) { double('gitlab_projects') }
  let(:timeout) { Gitlab.config.gitlab_shell.git_timeout }

  before do
    allow(Project).to receive(:find).and_return(project)

    allow(gitlab_shell).to receive(:gitlab_projects)
      .with(project.repository_storage_path, project.disk_path + '.git')
      .and_return(gitlab_projects)
  end

  it { is_expected.to respond_to :add_key }
  it { is_expected.to respond_to :remove_key }
  it { is_expected.to respond_to :add_repository }
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

  describe Gitlab::Shell::KeyAdder do
    describe '#add_key' do
      it 'removes trailing garbage' do
        io = spy(:io)
        adder = described_class.new(io)

        adder.add_key('key-42', "ssh-rsa foo bar\tbaz")

        expect(io).to have_received(:puts).with("key-42\tssh-rsa foo")
      end

      it 'handles multiple spaces in the key' do
        io = spy(:io)
        adder = described_class.new(io)

        adder.add_key('key-42', "ssh-rsa  foo")

        expect(io).to have_received(:puts).with("key-42\tssh-rsa foo")
      end

      it 'raises an exception if the key contains a tab' do
        expect do
          described_class.new(StringIO.new).add_key('key-42', "ssh-rsa\tfoobar")
        end.to raise_error(Gitlab::Shell::Error)
      end

      it 'raises an exception if the key contains a newline' do
        expect do
          described_class.new(StringIO.new).add_key('key-42', "ssh-rsa foobar\nssh-rsa pawned")
        end.to raise_error(Gitlab::Shell::Error)
      end
    end
  end

  describe 'projects commands' do
    let(:gitlab_shell_path) { File.expand_path('tmp/tests/gitlab-shell') }
    let(:projects_path) { File.join(gitlab_shell_path, 'bin/gitlab-projects') }
    let(:gitlab_shell_hooks_path) { File.join(gitlab_shell_path, 'hooks') }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:path).and_return(gitlab_shell_path)
      allow(Gitlab.config.gitlab_shell).to receive(:hooks_path).and_return(gitlab_shell_hooks_path)
      allow(Gitlab.config.gitlab_shell).to receive(:git_timeout).and_return(800)
    end

    describe '#add_key' do
      it 'removes trailing garbage' do
        allow(gitlab_shell).to receive(:gitlab_shell_keys_path).and_return(:gitlab_shell_keys_path)
        expect(gitlab_shell).to receive(:gitlab_shell_fast_execute).with(
          [:gitlab_shell_keys_path, 'add-key', 'key-123', 'ssh-rsa foobar']
        )

        gitlab_shell.add_key('key-123', 'ssh-rsa foobar trailing garbage')
      end
    end

    describe '#add_repository' do
      shared_examples '#add_repository' do
        let(:repository_storage) { 'default' }
        let(:repository_storage_path) { Gitlab.config.repositories.storages[repository_storage]['path'] }
        let(:repo_name) { 'project/path' }
        let(:created_path) { File.join(repository_storage_path, repo_name + '.git') }

        after do
          FileUtils.rm_rf(created_path)
        end

        it 'creates a repository' do
          expect(gitlab_shell.add_repository(repository_storage, repo_name)).to be_truthy

          expect(File.stat(created_path).mode & 0o777).to eq(0o770)

          hooks_path = File.join(created_path, 'hooks')
          expect(File.lstat(hooks_path)).to be_symlink
          expect(File.realpath(hooks_path)).to eq(gitlab_shell_hooks_path)
        end

        it 'returns false when the command fails' do
          FileUtils.mkdir_p(File.dirname(created_path))
          # This file will block the creation of the repo's .git directory. That
          # should cause #add_repository to fail.
          FileUtils.touch(created_path)

          expect(gitlab_shell.add_repository(repository_storage, repo_name)).to be_falsy
        end
      end

      context 'with gitaly' do
        it_behaves_like '#add_repository'
      end

      context 'without gitaly', :skip_gitaly_mock do
        it_behaves_like '#add_repository'
      end
    end

    describe '#remove_repository' do
      subject { gitlab_shell.remove_repository(project.repository_storage_path, project.disk_path) }

      it 'returns true when the command succeeds' do
        expect(gitlab_projects).to receive(:rm_project) { true }

        is_expected.to be_truthy
      end

      it 'returns false when the command fails' do
        expect(gitlab_projects).to receive(:rm_project) { false }

        is_expected.to be_falsy
      end
    end

    describe '#mv_repository' do
      it 'returns true when the command succeeds' do
        expect(gitlab_projects).to receive(:mv_project).with('project/newpath.git') { true }

        expect(gitlab_shell.mv_repository(project.repository_storage_path, project.disk_path, 'project/newpath')).to be_truthy
      end

      it 'returns false when the command fails' do
        expect(gitlab_projects).to receive(:mv_project).with('project/newpath.git') { false }

        expect(gitlab_shell.mv_repository(project.repository_storage_path, project.disk_path, 'project/newpath')).to be_falsy
      end
    end

    describe '#fork_repository' do
      subject do
        gitlab_shell.fork_repository(
          project.repository_storage_path,
          project.disk_path,
          'new/storage',
          'fork/path'
        )
      end

      it 'returns true when the command succeeds' do
        expect(gitlab_projects).to receive(:fork_repository).with('new/storage', 'fork/path.git') { true }

        is_expected.to be_truthy
      end

      it 'return false when the command fails' do
        expect(gitlab_projects).to receive(:fork_repository).with('new/storage', 'fork/path.git') { false }

        is_expected.to be_falsy
      end
    end

    shared_examples 'fetch_remote' do |gitaly_on|
      let(:repository) { project.repository }

      def fetch_remote(ssh_auth = nil)
        gitlab_shell.fetch_remote(repository.raw_repository, 'remote-name', ssh_auth: ssh_auth)
      end

      def expect_gitlab_projects(fail = false, options = {})
        expect(gitlab_projects).to receive(:fetch_remote).with(
          'remote-name',
          timeout,
          options
        ).and_return(!fail)

        allow(gitlab_projects).to receive(:output).and_return('error') if fail
      end

      def expect_gitaly_call(fail, options = {})
        receive_fetch_remote =
          if fail
            receive(:fetch_remote).and_raise(GRPC::NotFound)
          else
            receive(:fetch_remote).and_return(true)
          end

        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive_fetch_remote
      end

      if gitaly_on
        def expect_call(fail, options = {})
          expect_gitaly_call(fail, options)
        end
      else
        def expect_call(fail, options = {})
          expect_gitlab_projects(fail, options)
        end
      end

      def build_ssh_auth(opts = {})
        defaults = {
          ssh_import?: true,
          ssh_key_auth?: false,
          ssh_known_hosts: nil,
          ssh_private_key: nil
        }

        double(:ssh_auth, defaults.merge(opts))
      end

      it 'returns true when the command succeeds' do
        expect_call(false, force: false, tags: true)

        expect(fetch_remote).to be_truthy
      end

      it 'raises an exception when the command fails' do
        expect_call(true, force: false, tags: true)

        expect { fetch_remote }.to raise_error(Gitlab::Shell::Error)
      end

      it 'allows forced and no_tags to be changed' do
        expect_call(false, force: true, tags: false)

        result = gitlab_shell.fetch_remote(repository.raw_repository, 'remote-name', forced: true, no_tags: true)
        expect(result).to be_truthy
      end

      context 'SSH auth' do
        it 'passes the SSH key if specified' do
          expect_call(false, force: false, tags: true, ssh_key: 'foo')

          ssh_auth = build_ssh_auth(ssh_key_auth?: true, ssh_private_key: 'foo')

          expect(fetch_remote(ssh_auth)).to be_truthy
        end

        it 'does not pass an empty SSH key' do
          expect_call(false, force: false, tags: true)

          ssh_auth = build_ssh_auth(ssh_key_auth: true, ssh_private_key: '')

          expect(fetch_remote(ssh_auth)).to be_truthy
        end

        it 'does not pass the key unless SSH key auth is to be used' do
          expect_call(false, force: false, tags: true)

          ssh_auth = build_ssh_auth(ssh_key_auth: false, ssh_private_key: 'foo')

          expect(fetch_remote(ssh_auth)).to be_truthy
        end

        it 'passes the known_hosts data if specified' do
          expect_call(false, force: false, tags: true, known_hosts: 'foo')

          ssh_auth = build_ssh_auth(ssh_known_hosts: 'foo')

          expect(fetch_remote(ssh_auth)).to be_truthy
        end

        it 'does not pass empty known_hosts data' do
          expect_call(false, force: false, tags: true)

          ssh_auth = build_ssh_auth(ssh_known_hosts: '')

          expect(fetch_remote(ssh_auth)).to be_truthy
        end

        it 'does not pass known_hosts data unless SSH is to be used' do
          expect_call(false, force: false, tags: true)

          ssh_auth = build_ssh_auth(ssh_import?: false, ssh_known_hosts: 'foo')

          expect(fetch_remote(ssh_auth)).to be_truthy
        end
      end
    end

    describe '#fetch_remote local', :skip_gitaly_mock do
      it_should_behave_like 'fetch_remote', false
    end

    describe '#fetch_remote gitaly' do
      it_should_behave_like 'fetch_remote', true
    end

    describe '#import_repository' do
      let(:import_url) { 'https://gitlab.com/gitlab-org/gitlab-ce.git' }

      it 'returns true when the command succeeds' do
        expect(gitlab_projects).to receive(:import_project).with(import_url, timeout) { true }

        result = gitlab_shell.import_repository(project.repository_storage_path, project.disk_path, import_url)

        expect(result).to be_truthy
      end

      it 'raises an exception when the command fails' do
        allow(gitlab_projects).to receive(:output) { 'error' }
        expect(gitlab_projects).to receive(:import_project) { false }

        expect do
          gitlab_shell.import_repository(project.repository_storage_path, project.disk_path, import_url)
        end.to raise_error(Gitlab::Shell::Error, "error")
      end
    end

    describe '#push_remote_branches' do
      subject(:result) do
        gitlab_shell.push_remote_branches(
          project.repository_storage_path,
          project.disk_path,
          'downstream-remote',
          ['master']
        )
      end

      it 'executes the command' do
        expect(gitlab_projects).to receive(:push_branches)
          .with('downstream-remote', timeout, true, ['master'])
          .and_return(true)

        is_expected.to be_truthy
      end

      it 'fails to execute the command' do
        allow(gitlab_projects).to receive(:output) { 'error' }
        expect(gitlab_projects).to receive(:push_branches)
          .with('downstream-remote', timeout, true, ['master'])
          .and_return(false)

        expect { result }.to raise_error(Gitlab::Shell::Error, 'error')
      end
    end

    describe '#delete_remote_branches' do
      subject(:result) do
        gitlab_shell.delete_remote_branches(
          project.repository_storage_path,
          project.disk_path,
          'downstream-remote',
          ['master']
        )
      end

      it 'executes the command' do
        expect(gitlab_projects).to receive(:delete_remote_branches)
          .with('downstream-remote', ['master'])
          .and_return(true)

        is_expected.to be_truthy
      end

      it 'fails to execute the command' do
        allow(gitlab_projects).to receive(:output) { 'error' }
        expect(gitlab_projects).to receive(:delete_remote_branches)
          .with('downstream-remote', ['master'])
          .and_return(false)

        expect { result }.to raise_error(Gitlab::Shell::Error, 'error')
      end
    end
  end

  describe 'namespace actions' do
    subject { described_class.new }
    let(:storage_path) { Gitlab.config.repositories.storages.default.path }

    describe '#add_namespace' do
      it 'creates a namespace' do
        subject.add_namespace(storage_path, "mepmep")

        expect(subject.exists?(storage_path, "mepmep")).to be(true)
      end
    end

    describe '#exists?' do
      context 'when the namespace does not exist' do
        it 'returns false' do
          expect(subject.exists?(storage_path, "non-existing")).to be(false)
        end
      end

      context 'when the namespace exists' do
        it 'returns true' do
          subject.add_namespace(storage_path, "mepmep")

          expect(subject.exists?(storage_path, "mepmep")).to be(true)
        end
      end
    end

    describe '#remove' do
      it 'removes the namespace' do
        subject.add_namespace(storage_path, "mepmep")
        subject.rm_namespace(storage_path, "mepmep")

        expect(subject.exists?(storage_path, "mepmep")).to be(false)
      end
    end

    describe '#mv_namespace' do
      it 'renames the namespace' do
        subject.add_namespace(storage_path, "mepmep")
        subject.mv_namespace(storage_path, "mepmep", "2mep")

        expect(subject.exists?(storage_path, "mepmep")).to be(false)
        expect(subject.exists?(storage_path, "2mep")).to be(true)
      end
    end
  end
end
