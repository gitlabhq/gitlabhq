require 'spec_helper'
require 'stringio'

describe Gitlab::Shell, lib: true do
  let(:project) { double('Project', id: 7, path: 'diaspora') }
  let(:gitlab_shell) { Gitlab::Shell.new }

  before do
    allow(Project).to receive(:find).and_return(project)
  end

  it { is_expected.to respond_to :add_key }
  it { is_expected.to respond_to :remove_key }
  it { is_expected.to respond_to :add_repository }
  it { is_expected.to respond_to :remove_repository }
  it { is_expected.to respond_to :fork_repository }
  it { is_expected.to respond_to :gc }
  it { is_expected.to respond_to :add_namespace }
  it { is_expected.to respond_to :rm_namespace }
  it { is_expected.to respond_to :mv_namespace }
  it { is_expected.to respond_to :exists? }

  it { expect(gitlab_shell.url_to_repo('diaspora')).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + "diaspora.git") }

  describe 'generate_and_link_secret_token' do
    let(:secret_file) { 'tmp/tests/.secret_shell_test' }
    let(:link_file) { 'tmp/tests/shell-secret-test/.gitlab_shell_secret' }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:path).and_return('tmp/tests/shell-secret-test')
      allow(Gitlab.config.gitlab_shell).to receive(:secret_file).and_return(secret_file)
      FileUtils.mkdir('tmp/tests/shell-secret-test')
      gitlab_shell.generate_and_link_secret_token
    end

    after do
      FileUtils.rm_rf('tmp/tests/shell-secret-test')
      FileUtils.rm_rf(secret_file)
    end

    it 'creates and links the secret token file' do
      expect(File.exist?(secret_file)).to be(true)
      expect(File.symlink?(link_file)).to be(true)
      expect(File.readlink(link_file)).to eq(secret_file)
    end
  end

  describe '#add_key' do
    it 'removes trailing garbage' do
      allow(gitlab_shell).to receive(:gitlab_shell_keys_path).and_return(:gitlab_shell_keys_path)
      expect(Gitlab::Utils).to receive(:system_silent).with(
        [:gitlab_shell_keys_path, 'add-key', 'key-123', 'ssh-rsa foobar']
      )

      gitlab_shell.add_key('key-123', 'ssh-rsa foobar trailing garbage')
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
end
