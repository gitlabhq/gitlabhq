require 'spec_helper'
require 'stringio'

describe Gitlab::Shell, lib: true do
  let(:project) { double('Project', id: 7, path: 'diaspora') }
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:popen_vars) { { 'GIT_TERMINAL_PROMPT' => ENV['GIT_TERMINAL_PROMPT'] } }

  before do
    allow(Project).to receive(:find).and_return(project)
  end

  it { is_expected.to respond_to :add_key }
  it { is_expected.to respond_to :remove_key }
  it { is_expected.to respond_to :add_repository }
  it { is_expected.to respond_to :remove_repository }
  it { is_expected.to respond_to :fork_repository }
  it { is_expected.to respond_to :add_namespace }
  it { is_expected.to respond_to :rm_namespace }
  it { is_expected.to respond_to :mv_namespace }
  it { is_expected.to respond_to :exists? }

  it { expect(gitlab_shell.url_to_repo('diaspora')).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + "diaspora.git") }

  describe 'memoized secret_token' do
    let(:secret_file) { 'tmp/tests/.secret_shell_test' }
    let(:link_file) { 'tmp/tests/shell-secret-test/.gitlab_shell_secret' }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:secret_file).and_return(secret_file)
      allow(Gitlab.config.gitlab_shell).to receive(:path).and_return('tmp/tests/shell-secret-test')
      FileUtils.mkdir('tmp/tests/shell-secret-test')
      Gitlab::Shell.ensure_secret_token!
    end

    after do
      FileUtils.rm_rf('tmp/tests/shell-secret-test')
      FileUtils.rm_rf(secret_file)
    end

    it 'creates and links the secret token file' do
      secret_token = Gitlab::Shell.secret_token

      expect(File.exist?(secret_file)).to be(true)
      expect(File.read(secret_file).chomp).to eq(secret_token)
      expect(File.symlink?(link_file)).to be(true)
      expect(File.readlink(link_file)).to eq(secret_file)
    end
  end

  describe 'projects commands' do
    let(:projects_path) { 'tmp/tests/shell-projects-test/bin/gitlab-projects' }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:path).and_return('tmp/tests/shell-projects-test')
    end

    describe '#mv_repository' do
      it 'executes the command' do
        expect(gitlab_shell).to receive(:gitlab_shell_fast_execute).with(
          [projects_path, 'mv-project', 'storage/path', 'project/path.git', 'new/path.git']
        )
        gitlab_shell.mv_repository('storage/path', 'project/path', 'new/path')
      end
    end

    describe '#mv_storage' do
      it 'executes the command' do
        expect(Gitlab::Utils).to receive(:system_silent)
          .with([projects_path, 'mv-storage', 'current/storage', 'project/path.git', 'new/storage'])
        gitlab_shell.mv_storage('current/storage', 'project/path', 'new/storage')
      end
    end

    describe '#push_remote_branches' do
      it 'executes the command' do
        expect(Gitlab::Popen).to receive(:popen)
        .with([projects_path, 'push-branches', 'current/storage', 'project/path.git', 'new/storage', '600', 'master']).and_return([nil, 0])

        expect(gitlab_shell.push_remote_branches('current/storage', 'project/path', 'new/storage', ['master'])).to be true
      end

      it 'fails to execute the command' do
        expect(Gitlab::Popen).to receive(:popen)
        .with([projects_path, 'push-branches', 'current/storage', 'project/path.git', 'new/storage', '600', 'master']).and_return(["error", 1])

        expect { gitlab_shell.push_remote_branches('current/storage', 'project/path', 'new/storage', ['master']) }.to raise_error(Gitlab::Shell::Error, "error")
      end
    end
  end

  describe '#add_key' do
    context 'when authorized_keys_enabled is true' do
      it 'removes trailing garbage' do
        allow(gitlab_shell).to receive(:gitlab_shell_keys_path).and_return(:gitlab_shell_keys_path)
        expect(gitlab_shell).to receive(:gitlab_shell_fast_execute).with(
          [:gitlab_shell_keys_path, 'add-key', 'key-123', 'ssh-rsa foobar']
        )

        gitlab_shell.add_key('key-123', 'ssh-rsa foobar trailing garbage')
      end
    end

    context 'when authorized_keys_enabled is false' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does nothing' do
        expect(Gitlab::Utils).not_to receive(:system_silent)

        gitlab_shell.add_key('key-123', 'ssh-rsa foobar trailing garbage')
      end
    end

    context 'when authorized_keys_enabled is nil' do
      before do
        stub_application_setting(authorized_keys_enabled: nil)
      end

      it 'removes trailing garbage' do
        allow(gitlab_shell).to receive(:gitlab_shell_keys_path).and_return(:gitlab_shell_keys_path)
        expect(gitlab_shell).to receive(:gitlab_shell_fast_execute).with(
          [:gitlab_shell_keys_path, 'add-key', 'key-123', 'ssh-rsa foobar']
        )

        gitlab_shell.add_key('key-123', 'ssh-rsa foobar trailing garbage')
      end
    end
  end

  describe '#batch_add_keys' do
    context 'when authorized_keys_enabled is true' do
      it 'instantiates KeyAdder' do
        expect_any_instance_of(Gitlab::Shell::KeyAdder).to receive(:add_key).with('key-123', 'ssh-rsa foobar')

        gitlab_shell.batch_add_keys do |adder|
          adder.add_key('key-123', 'ssh-rsa foobar')
        end
      end
    end

    context 'when authorized_keys_enabled is false' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does nothing' do
        expect_any_instance_of(Gitlab::Shell::KeyAdder).not_to receive(:add_key)

        gitlab_shell.batch_add_keys do |adder|
          adder.add_key('key-123', 'ssh-rsa foobar')
        end
      end
    end

    context 'when authorized_keys_enabled is nil' do
      before do
        stub_application_setting(authorized_keys_enabled: nil)
      end

      it 'instantiates KeyAdder' do
        expect_any_instance_of(Gitlab::Shell::KeyAdder).to receive(:add_key).with('key-123', 'ssh-rsa foobar')

        gitlab_shell.batch_add_keys do |adder|
          adder.add_key('key-123', 'ssh-rsa foobar')
        end
      end
    end
  end

  describe '#remove_key' do
    context 'when authorized_keys_enabled is true' do
      it 'removes trailing garbage' do
        allow(gitlab_shell).to receive(:gitlab_shell_keys_path).and_return(:gitlab_shell_keys_path)
        expect(gitlab_shell).to receive(:gitlab_shell_fast_execute).with(
          [:gitlab_shell_keys_path, 'rm-key', 'key-123', 'ssh-rsa foobar']
        )

        gitlab_shell.remove_key('key-123', 'ssh-rsa foobar')
      end
    end

    context 'when authorized_keys_enabled is false' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does nothing' do
        expect(gitlab_shell).not_to receive(:gitlab_shell_fast_execute)

        gitlab_shell.remove_key('key-123', 'ssh-rsa foobar')
      end
    end

    context 'when authorized_keys_enabled is nil' do
      before do
        stub_application_setting(authorized_keys_enabled: nil)
      end

      it 'removes trailing garbage' do
        allow(gitlab_shell).to receive(:gitlab_shell_keys_path).and_return(:gitlab_shell_keys_path)
        expect(gitlab_shell).to receive(:gitlab_shell_fast_execute).with(
          [:gitlab_shell_keys_path, 'rm-key', 'key-123', 'ssh-rsa foobar']
        )

        gitlab_shell.remove_key('key-123', 'ssh-rsa foobar')
      end
    end

    context 'when key content is not given' do
      it 'calls rm-key with only one argument' do
        allow(gitlab_shell).to receive(:gitlab_shell_keys_path).and_return(:gitlab_shell_keys_path)
        expect(gitlab_shell).to receive(:gitlab_shell_fast_execute).with(
          [:gitlab_shell_keys_path, 'rm-key', 'key-123']
        )

        gitlab_shell.remove_key('key-123')
      end
    end
  end

  describe '#remove_all_keys' do
    context 'when authorized_keys_enabled is true' do
      it 'removes trailing garbage' do
        allow(gitlab_shell).to receive(:gitlab_shell_keys_path).and_return(:gitlab_shell_keys_path)
        expect(gitlab_shell).to receive(:gitlab_shell_fast_execute).with([:gitlab_shell_keys_path, 'clear'])

        gitlab_shell.remove_all_keys
      end
    end

    context 'when authorized_keys_enabled is false' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it 'does nothing' do
        expect(gitlab_shell).not_to receive(:gitlab_shell_fast_execute)

        gitlab_shell.remove_all_keys
      end
    end

    context 'when authorized_keys_enabled is nil' do
      before do
        stub_application_setting(authorized_keys_enabled: nil)
      end

      it 'removes trailing garbage' do
        allow(gitlab_shell).to receive(:gitlab_shell_keys_path).and_return(:gitlab_shell_keys_path)
        expect(gitlab_shell).to receive(:gitlab_shell_fast_execute).with(
          [:gitlab_shell_keys_path, 'clear']
        )

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
        expect(find_in_authorized_keys_file(1234)).to be_truthy
        expect(find_in_authorized_keys_file(9876)).to be_truthy
        expect(find_in_authorized_keys_file(@another_key.id)).to be_truthy
        gitlab_shell.remove_keys_not_found_in_db
        expect(find_in_authorized_keys_file(1234)).to be_falsey
        expect(find_in_authorized_keys_file(9876)).to be_falsey
        expect(find_in_authorized_keys_file(@another_key.id)).to be_truthy
      end
    end

    context 'when keys there are duplicate keys in the file that are not in the DB' do
      before do
        gitlab_shell.remove_all_keys
        gitlab_shell.add_key('key-1234', 'ssh-rsa ASDFASDF')
        gitlab_shell.add_key('key-1234', 'ssh-rsa ASDFASDF')
      end

      it 'removes the keys' do
        expect(find_in_authorized_keys_file(1234)).to be_truthy
        gitlab_shell.remove_keys_not_found_in_db
        expect(find_in_authorized_keys_file(1234)).to be_falsey
      end

      it 'does not run remove more than once per key (in a batch)' do
        expect(gitlab_shell).to receive(:remove_key).with('key-1234').once
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
        gitlab_shell.remove_keys_not_found_in_db
        expect(find_in_authorized_keys_file(@key.id)).to be_truthy
      end

      it 'does not need to run a SELECT query for that batch, on account of that key' do
        expect_any_instance_of(ActiveRecord::Relation).not_to receive(:pluck)
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
          expect(find_in_authorized_keys_file(1234)).to be_truthy
          gitlab_shell.remove_keys_not_found_in_db
          expect(find_in_authorized_keys_file(1234)).to be_falsey
        end
      end
    end
  end

  describe '#batch_read_key_ids' do
    context 'when there are keys in the authorized_keys file' do
      before do
        gitlab_shell.remove_all_keys
        (1..4).each do |i|
          gitlab_shell.add_key("key-#{i}", "ssh-rsa ASDFASDF#{i}")
        end
      end

      it 'iterates over the key IDs in the file, in batches' do
        loop_count = 0
        first_batch = [1, 2]
        second_batch = [3, 4]

        gitlab_shell.batch_read_key_ids(batch_size: 2) do |batch|
          expected = (loop_count == 0 ? first_batch : second_batch)
          expect(batch).to eq(expected)
          loop_count += 1
        end
      end
    end
  end

  describe '#list_key_ids' do
    context 'when there are keys in the authorized_keys file' do
      before do
        gitlab_shell.remove_all_keys
        (1..4).each do |i|
          gitlab_shell.add_key("key-#{i}", "ssh-rsa ASDFASDF#{i}")
        end
      end

      it 'outputs the key IDs in the file, separated by newlines' do
        ids = []
        gitlab_shell.list_key_ids do |io|
          io.each do |line|
            ids << line
          end
        end

        expect(ids).to eq(%W{1\n 2\n 3\n 4\n})
      end
    end

    context 'when there are no keys in the authorized_keys file' do
      before do
        gitlab_shell.remove_all_keys
      end

      it 'outputs nothing, not even an empty string' do
        ids = []
        gitlab_shell.list_key_ids do |io|
          io.each do |line|
            ids << line
          end
        end

        expect(ids).to eq([])
      end
    end
  end

  describe Gitlab::Shell::KeyAdder, lib: true do
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
    let(:projects_path) { 'tmp/tests/shell-projects-test/bin/gitlab-projects' }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:path).and_return('tmp/tests/shell-projects-test')
      allow(Gitlab.config.gitlab_shell).to receive(:git_timeout).and_return(800)
    end

    describe '#add_repository' do
      it 'returns true when the command succeeds' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'add-project', 'current/storage', 'project/path.git'],
                nil, popen_vars).and_return([nil, 0])

        expect(gitlab_shell.add_repository('current/storage', 'project/path')).to be true
      end

      it 'returns false when the command fails' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'add-project', 'current/storage', 'project/path.git'],
                nil, popen_vars).and_return(["error", 1])

        expect(gitlab_shell.add_repository('current/storage', 'project/path')).to be false
      end
    end

    describe '#remove_repository' do
      it 'returns true when the command succeeds' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'rm-project', 'current/storage', 'project/path.git'],
                nil, popen_vars).and_return([nil, 0])

        expect(gitlab_shell.remove_repository('current/storage', 'project/path')).to be true
      end

      it 'returns false when the command fails' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'rm-project', 'current/storage', 'project/path.git'],
                nil, popen_vars).and_return(["error", 1])

        expect(gitlab_shell.remove_repository('current/storage', 'project/path')).to be false
      end
    end

    describe '#mv_repository' do
      it 'returns true when the command succeeds' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'mv-project', 'current/storage', 'project/path.git', 'project/newpath.git'],
                nil, popen_vars).and_return([nil, 0])

        expect(gitlab_shell.mv_repository('current/storage', 'project/path', 'project/newpath')).to be true
      end

      it 'returns false when the command fails' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'mv-project', 'current/storage', 'project/path.git', 'project/newpath.git'],
                nil, popen_vars).and_return(["error", 1])

        expect(gitlab_shell.mv_repository('current/storage', 'project/path', 'project/newpath')).to be false
      end
    end

    describe '#fork_repository' do
      it 'returns true when the command succeeds' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'fork-project', 'current/storage', 'project/path.git', 'new/storage', 'new-namespace'],
                nil, popen_vars).and_return([nil, 0])

        expect(gitlab_shell.fork_repository('current/storage', 'project/path', 'new/storage', 'new-namespace')).to be true
      end

      it 'return false when the command fails' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'fork-project', 'current/storage', 'project/path.git', 'new/storage', 'new-namespace'],
                nil, popen_vars).and_return(["error", 1])

        expect(gitlab_shell.fork_repository('current/storage', 'project/path', 'new/storage', 'new-namespace')).to be false
      end
    end

    describe '#fetch_remote' do
      it 'returns true when the command succeeds' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'fetch-remote', 'current/storage', 'project/path.git', 'new/storage', '800'],
                nil, popen_vars).and_return([nil, 0])

        expect(gitlab_shell.fetch_remote('current/storage', 'project/path', 'new/storage')).to be true
      end

      it 'raises an exception when the command fails' do
        expect(Gitlab::Popen).to receive(:popen)
        .with([projects_path, 'fetch-remote', 'current/storage', 'project/path.git', 'new/storage', '800'],
              nil, popen_vars).and_return(["error", 1])

        expect { gitlab_shell.fetch_remote('current/storage', 'project/path', 'new/storage') }.to raise_error(Gitlab::Shell::Error, "error")
      end
    end

    describe '#import_repository' do
      it 'returns true when the command succeeds' do
        expect(Gitlab::Popen).to receive(:popen)
          .with([projects_path, 'import-project', 'current/storage', 'project/path.git', 'https://gitlab.com/gitlab-org/gitlab-ce.git', "800"],
                nil, popen_vars).and_return([nil, 0])

        expect(gitlab_shell.import_repository('current/storage', 'project/path', 'https://gitlab.com/gitlab-org/gitlab-ce.git')).to be true
      end

      it 'raises an exception when the command fails' do
        expect(Gitlab::Popen).to receive(:popen)
        .with([projects_path, 'import-project', 'current/storage', 'project/path.git', 'https://gitlab.com/gitlab-org/gitlab-ce.git', "800"],
              nil, popen_vars).and_return(["error", 1])

        expect { gitlab_shell.import_repository('current/storage', 'project/path', 'https://gitlab.com/gitlab-org/gitlab-ce.git') }.to raise_error(Gitlab::Shell::Error, "error")
      end
    end
  end

  def find_in_authorized_keys_file(key_id)
    gitlab_shell.batch_read_key_ids do |ids|
      return true if ids.include?(key_id)
    end

    false
  end
end
