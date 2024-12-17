# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TaskHelpers do
  let(:repo) { 'https://gitlab.com/gitlab-org/gitlab-test.git' }
  let(:clone_path) { Rails.root.join('tmp/tests/task_helpers_tests').to_s }
  let(:version) { '1.1.0' }
  let(:tag) { 'v1.1.0' }

  subject { Class.new { include Gitlab::TaskHelpers }.new }

  describe '#checkout_or_clone_version' do
    before do
      allow(subject).to receive(:run_command!)
    end

    it 'checkout the version and reset to it' do
      expect(subject).to receive(:get_version).with(version).and_call_original
      expect(subject).to receive(:checkout_version).with(tag, clone_path)

      subject.checkout_or_clone_version(version: version, repo: repo, target_dir: clone_path)
    end

    context "target_dir doesn't exist" do
      it 'clones the repo' do
        expect(subject).to receive(:clone_repo).with(repo, clone_path, clone_opts: [])

        subject.checkout_or_clone_version(version: version, repo: repo, target_dir: clone_path)
      end
    end

    context 'target_dir exists' do
      before do
        expect(Dir).to receive(:exist?).and_return(true)
      end

      it "doesn't clone the repository" do
        expect(subject).not_to receive(:clone_repo)

        subject.checkout_or_clone_version(version: version, repo: repo, target_dir: clone_path)
      end
    end

    it 'accepts clone_opts' do
      expect(subject).to receive(:clone_repo).with(repo, clone_path, clone_opts: %w[--depth 1])

      subject.checkout_or_clone_version(version: version, repo: repo, target_dir: clone_path, clone_opts: %w[--depth 1])
    end
  end

  describe '#clone_repo' do
    it 'clones the repo in the target dir' do
      expect(subject)
        .to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} clone -- #{repo} #{clone_path}])

      subject.clone_repo(repo, clone_path)
    end

    it 'accepts clone_opts' do
      expect(subject)
        .to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} clone --depth 1 -- #{repo} #{clone_path}])

      subject.clone_repo(repo, clone_path, clone_opts: %w[--depth 1])
    end
  end

  describe '#checkout_version' do
    it 'clones the repo in the target dir' do
      expect(subject)
        .to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} config protocol.version 2])
      expect(subject)
        .to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} fetch --quiet origin #{tag}])
      expect(subject)
        .to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} checkout -f --quiet FETCH_HEAD --])

      subject.checkout_version(tag, clone_path)
    end
  end

  describe '#run_command' do
    it 'runs command and return the output' do
      expect(subject.run_command(%w[echo it works!])).to eq("it works!\n")
    end

    it 'returns empty string when command doesnt exist' do
      expect(subject.run_command(%w[nonexistentcommand with arguments])).to eq('')
    end
  end

  describe '#run_command!' do
    it 'runs command and return the output' do
      expect(subject.run_command!(%w[echo it works!])).to eq("it works!\n")
    end

    it 'returns and exception when command exit with non zero code' do
      expect { subject.run_command!(['bash', '-c', 'exit 1']) }.to raise_error Gitlab::TaskFailedError
    end
  end

  describe '#download_package_file_version' do
    let(:version) { 'some/version' }
    let(:project_path) { 'path/to/project' }
    let(:repo) { "https://gitlab.com/#{project_path}.git" }
    let(:package_name) { 'some/package' }
    let(:package_file) { 'some/file' }
    let(:target_path) { Tempfile.new }
    let(:file_contents) { 'content' }
    let(:checksums) { { package_file => Digest::SHA256.hexdigest(file_contents) } }
    let(:response_status) { 200 }

    let(:api_download_url) do
      format(
        'https://gitlab.com/api/v4/projects/%{project_path}/packages/generic/%{package}/%{version}/%{file}',
        project_path: CGI.escape(project_path),
        package: CGI.escape(package_name),
        version: CGI.escape(version),
        file: CGI.escape(package_file)
      )
    end

    subject(:download) do
      described_class.download_package_file_version(
        version: version, repo: repo, package_name: package_name, package_file: package_file,
        package_checksums_sha256: checksums, target_path: target_path
      )
    end

    before do
      stub_request(:get, api_download_url).to_return(status: response_status, body: file_contents)
    end

    after do
      target_path.unlink
    end

    context 'when download is successful' do
      context 'and checksum matches' do
        it 'saves the file atomically and returns true' do
          expect(FileUtils).to receive(:mkdir_p).with(File.dirname(target_path)).and_call_original
          expect(FileUtils).to receive(:mv).with(a_kind_of(File), target_path).and_call_original

          expect(download).to be(true)
          expect(File.read(target_path)).to eq(file_contents)
        end
      end

      context 'and checksum mismatches' do
        let(:checksums) { { package_file => 'badcoffee' } }

        it 'raises an error' do
          expect { download }.to raise_error do |exception|
            expect(exception.message)
              .to include("ERROR: Checksum mismatch for `#{package_file}`:")
              .and include('Expected: "badcoffee"')
              .and include(/Actual: "\h{64}"$/)
          end
          expect(File.read(target_path)).to eq('')
        end
      end
    end

    context 'when download returns 404' do
      let(:response_status) { 404 }

      it 'warns about the failure returns false' do
        expect do
          expect(download).to be(false)
        end.to output(/HTTP Code: 404 for #{api_download_url}/).to_stderr

        expect(File.read(target_path)).to eq('')
      end
    end

    context 'when download returns 302' do
      let(:response_status) { 302 }

      it 'follow redirects' do
        # See https://github.com/bblimke/webmock/issues/237
        skip 'webmock does not support following redirects'
      end
    end
  end

  describe '#get_version' do
    using RSpec::Parameterized::TableSyntax

    where(:version, :result) do
      '1.1.1'                                    | 'v1.1.1'
      'master'                                   | 'master'
      '12.4.0-rc7'                               | 'v12.4.0-rc7'
      '594c3ea3e0e5540e5915bd1c49713a0381459dd6' | '594c3ea3e0e5540e5915bd1c49713a0381459dd6'
    end

    with_them do
      it { expect(subject.get_version(version)).to eq(result) }
    end
  end
end
