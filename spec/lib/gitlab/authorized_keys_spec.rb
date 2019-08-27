# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::AuthorizedKeys do
  let(:logger) { double('logger').as_null_object }

  subject { described_class.new(logger) }

  describe '#accessible?' do
    context 'authorized_keys file exists' do
      before do
        create_authorized_keys_fixture
      end

      after do
        delete_authorized_keys_file
      end

      context 'can open file' do
        it 'returns true' do
          expect(subject.accessible?).to eq(true)
        end
      end

      context 'cannot open file' do
        before do
          allow(File).to receive(:open).and_raise(Errno::EACCES)
        end

        it 'returns false' do
          expect(subject.accessible?).to eq(false)
        end
      end
    end

    context 'authorized_keys file does not exist' do
      it 'returns false' do
        expect(subject.accessible?).to eq(false)
      end
    end
  end

  describe '#add_key' do
    context 'authorized_keys file exists' do
      before do
        create_authorized_keys_fixture
      end

      after do
        delete_authorized_keys_file
      end

      it "adds a line at the end of the file and strips trailing garbage" do
        auth_line = "command=\"#{Gitlab.config.gitlab_shell.path}/bin/gitlab-shell key-741\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-rsa AAAAB3NzaDAxx2E"

        expect(logger).to receive(:info).with('Adding key (key-741): ssh-rsa AAAAB3NzaDAxx2E')
        expect(subject.add_key('key-741', 'ssh-rsa AAAAB3NzaDAxx2E trailing garbage'))
          .to be_truthy
        expect(File.read(tmp_authorized_keys_path)).to eq("existing content\n#{auth_line}\n")
      end
    end

    context 'authorized_keys file does not exist' do
      before do
        delete_authorized_keys_file
      end

      it 'creates the file' do
        expect(subject.add_key('key-741', 'ssh-rsa AAAAB3NzaDAxx2E')).to be_truthy
        expect(File.exist?(tmp_authorized_keys_path)).to be_truthy
      end
    end
  end

  describe '#batch_add_keys' do
    let(:keys) do
      [
        double(shell_id: 'key-12', key: 'ssh-dsa ASDFASGADG trailing garbage'),
        double(shell_id: 'key-123', key: 'ssh-rsa GFDGDFSGSDFG')
      ]
    end

    context 'authorized_keys file exists' do
      before do
        create_authorized_keys_fixture
      end

      after do
        delete_authorized_keys_file
      end

      it "adds lines at the end of the file" do
        auth_line1 = "command=\"#{Gitlab.config.gitlab_shell.path}/bin/gitlab-shell key-12\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-dsa ASDFASGADG"
        auth_line2 = "command=\"#{Gitlab.config.gitlab_shell.path}/bin/gitlab-shell key-123\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-rsa GFDGDFSGSDFG"

        expect(logger).to receive(:info).with('Adding key (key-12): ssh-dsa ASDFASGADG')
        expect(logger).to receive(:info).with('Adding key (key-123): ssh-rsa GFDGDFSGSDFG')
        expect(subject.batch_add_keys(keys)).to be_truthy
        expect(File.read(tmp_authorized_keys_path)).to eq("existing content\n#{auth_line1}\n#{auth_line2}\n")
      end

      context "invalid key" do
        let(:keys) { [double(shell_id: 'key-123', key: "ssh-rsa A\tSDFA\nSGADG")] }

        it "doesn't add keys" do
          expect(subject.batch_add_keys(keys)).to be_falsey
          expect(File.read(tmp_authorized_keys_path)).to eq("existing content\n")
        end
      end
    end

    context 'authorized_keys file does not exist' do
      before do
        delete_authorized_keys_file
      end

      it 'creates the file' do
        expect(subject.batch_add_keys(keys)).to be_truthy
        expect(File.exist?(tmp_authorized_keys_path)).to be_truthy
      end
    end
  end

  describe '#rm_key' do
    context 'authorized_keys file exists' do
      before do
        create_authorized_keys_fixture
      end

      after do
        delete_authorized_keys_file
      end

      it "removes the right line" do
        other_line = "command=\"#{Gitlab.config.gitlab_shell.path}/bin/gitlab-shell key-742\",options ssh-rsa AAAAB3NzaDAxx2E"
        delete_line = "command=\"#{Gitlab.config.gitlab_shell.path}/bin/gitlab-shell key-741\",options ssh-rsa AAAAB3NzaDAxx2E"
        erased_line = delete_line.gsub(/./, '#')
        File.open(tmp_authorized_keys_path, 'a') do |auth_file|
          auth_file.puts delete_line
          auth_file.puts other_line
        end

        expect(logger).to receive(:info).with('Removing key (key-741)')
        expect(subject.rm_key('key-741')).to be_truthy
        expect(File.read(tmp_authorized_keys_path)).to eq("existing content\n#{erased_line}\n#{other_line}\n")
      end
    end

    context 'authorized_keys file does not exist' do
      before do
        delete_authorized_keys_file
      end

      it 'returns false' do
        expect(subject.rm_key('key-741')).to be_falsey
      end
    end
  end

  describe '#clear' do
    context 'authorized_keys file exists' do
      before do
        create_authorized_keys_fixture
      end

      after do
        delete_authorized_keys_file
      end

      it "returns true" do
        expect(subject.clear).to be_truthy
      end
    end

    context 'authorized_keys file does not exist' do
      before do
        delete_authorized_keys_file
      end

      it "still returns true" do
        expect(subject.clear).to be_truthy
      end
    end
  end

  describe '#list_key_ids' do
    context 'authorized_keys file exists' do
      before do
        create_authorized_keys_fixture(
          existing_content:
            "key-1\tssh-dsa AAA\nkey-2\tssh-rsa BBB\nkey-3\tssh-rsa CCC\nkey-9000\tssh-rsa DDD\n"
        )
      end

      after do
        delete_authorized_keys_file
      end

      it 'returns array of key IDs' do
        expect(subject.list_key_ids).to eq([1, 2, 3, 9000])
      end
    end

    context 'authorized_keys file does not exist' do
      before do
        delete_authorized_keys_file
      end

      it 'returns an empty array' do
        expect(subject.list_key_ids).to be_empty
      end
    end
  end

  def create_authorized_keys_fixture(existing_content: 'existing content')
    FileUtils.mkdir_p(File.dirname(tmp_authorized_keys_path))
    File.open(tmp_authorized_keys_path, 'w') { |file| file.puts(existing_content) }
  end

  def delete_authorized_keys_file
    File.delete(tmp_authorized_keys_path) if File.exist?(tmp_authorized_keys_path)
  end

  def tmp_authorized_keys_path
    Gitlab.config.gitlab_shell.authorized_keys_file
  end
end
