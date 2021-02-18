# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Files do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project) }

  let(:status_0) { double('exit 0', success?: true, exitstatus: 0) }
  let(:status_1) { double('exit 1', success?: false, exitstatus: 1) }
  let(:status_2) { double('exit 2', success?: false, exitstatus: 2) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)
    allow(FileUtils).to receive(:mkdir_p).and_return(true)
    allow(FileUtils).to receive(:mv).and_return(true)
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:realpath).with("/var/gitlab-registry").and_return("/var/gitlab-registry")
    allow(File).to receive(:realpath).with("/var/gitlab-registry/..").and_return("/var")
    allow(File).to receive(:realpath).with("/var/gitlab-pages").and_return("/var/gitlab-pages")
    allow(File).to receive(:realpath).with("/var/gitlab-pages/..").and_return("/var")

    allow_any_instance_of(described_class).to receive(:progress).and_return(progress)
  end

  RSpec::Matchers.define :eq_statuslist do |expected|
    match do |actual|
      actual.map(&:exitstatus) == expected.map(&:exitstatus)
    end

    description do
      'be an Array of Process::Status with equal exitstatus against expected'
    end

    failure_message do |actual|
      "expected #{actual} exitstatuses list to be equal #{expected} exitstatuses list"
    end
  end

  describe '#restore' do
    subject { described_class.new('registry', '/var/gitlab-registry') }

    let(:timestamp) { Time.utc(2017, 3, 22) }

    around do |example|
      travel_to(timestamp) { example.run }
    end

    describe 'folders with permission' do
      before do
        allow(subject).to receive(:run_pipeline!).and_return([[true, true], ''])
        allow(subject).to receive(:backup_existing_files).and_return(true)
        allow(subject).to receive(:pipeline_succeeded?).and_return(true)
        allow(Dir).to receive(:glob).with("/var/gitlab-registry/*", File::FNM_DOTMATCH).and_return(["/var/gitlab-registry/.", "/var/gitlab-registry/..", "/var/gitlab-registry/sample1"])
      end

      it 'moves all necessary files' do
        allow(subject).to receive(:backup_existing_files).and_call_original
        expect(FileUtils).to receive(:mv).with(["/var/gitlab-registry/sample1"], File.join(Gitlab.config.backup.path, "tmp", "registry.#{Time.now.to_i}"))
        subject.restore
      end

      it 'raises no errors' do
        expect { subject.restore }.not_to raise_error
      end

      it 'calls tar command with unlink' do
        expect(subject).to receive(:tar).and_return('blabla-tar')

        expect(subject).to receive(:run_pipeline!).with([%w(gzip -cd), %w(blabla-tar --unlink-first --recursive-unlink -C /var/gitlab-registry -xf -)], any_args)
        expect(subject).to receive(:pipeline_succeeded?).and_return(true)
        subject.restore
      end

      it 'raises an error on failure' do
        expect(subject).to receive(:pipeline_succeeded?).and_return(false)

        expect { subject.restore }.to raise_error(/Restore operation failed:/)
      end
    end

    describe 'folders without permissions' do
      before do
        allow(FileUtils).to receive(:mv).and_raise(Errno::EACCES)
        allow(subject).to receive(:run_pipeline!).and_return([[true, true], ''])
        allow(subject).to receive(:pipeline_succeeded?).and_return(true)
      end

      it 'shows error message' do
        expect(subject).to receive(:access_denied_error).with("/var/gitlab-registry")
        subject.restore
      end
    end

    describe 'folders that are a mountpoint' do
      before do
        allow(FileUtils).to receive(:mv).and_raise(Errno::EBUSY)
        allow(subject).to receive(:run_pipeline!).and_return([[true, true], ''])
        allow(subject).to receive(:pipeline_succeeded?).and_return(true)
      end

      it 'shows error message' do
        expect(subject).to receive(:resource_busy_error).with("/var/gitlab-registry")
                             .and_call_original

        expect { subject.restore }.to raise_error(/is a mountpoint/)
      end
    end
  end

  describe '#dump' do
    subject { described_class.new('pages', '/var/gitlab-pages', excludes: ['@pages.tmp']) }

    before do
      allow(subject).to receive(:run_pipeline!).and_return([[true, true], ''])
      allow(subject).to receive(:pipeline_succeeded?).and_return(true)
    end

    it 'raises no errors' do
      expect { subject.dump }.not_to raise_error
    end

    it 'excludes tmp dirs from archive' do
      expect(subject).to receive(:tar).and_return('blabla-tar')

      expect(subject).to receive(:run_pipeline!).with([%w(blabla-tar --exclude=lost+found --exclude=./@pages.tmp -C /var/gitlab-pages -cf - .), 'gzip -c -1'], any_args)
      subject.dump
    end

    it 'raises an error on failure' do
      allow(subject).to receive(:run_pipeline!).and_return([[true, true], ''])
      expect(subject).to receive(:pipeline_succeeded?).and_return(false)

      expect do
        subject.dump
      end.to raise_error(/Backup operation failed:/)
    end

    describe 'with STRATEGY=copy' do
      before do
        stub_env('STRATEGY', 'copy')
        allow(Gitlab.config.backup).to receive(:path) { '/var/gitlab-backup' }
        allow(File).to receive(:realpath).with("/var/gitlab-backup").and_return("/var/gitlab-backup")
      end

      it 'excludes tmp dirs from rsync' do
        expect(Gitlab::Popen).to receive(:popen)
          .with(%w(rsync -a --delete --exclude=lost+found --exclude=/gitlab-pages/@pages.tmp /var/gitlab-pages /var/gitlab-backup))
          .and_return(['', 0])

        subject.dump
      end

      it 'retries if rsync fails due to vanishing files' do
        expect(Gitlab::Popen).to receive(:popen)
          .with(%w(rsync -a --delete --exclude=lost+found --exclude=/gitlab-pages/@pages.tmp /var/gitlab-pages /var/gitlab-backup))
          .and_return(['rsync failed', 24], ['', 0])

        expect do
          subject.dump
        end.to output(/files vanished during rsync, retrying/).to_stdout
      end

      it 'raises an error and outputs an error message if rsync failed' do
        allow(Gitlab::Popen).to receive(:popen)
          .with(%w(rsync -a --delete --exclude=lost+found --exclude=/gitlab-pages/@pages.tmp /var/gitlab-pages /var/gitlab-backup))
          .and_return(['rsync failed', 1])

        expect do
          subject.dump
        end.to output(/rsync failed/).to_stdout
           .and raise_error(/Backup failed/)
      end
    end
  end

  describe '#exclude_dirs' do
    subject { described_class.new('pages', '/var/gitlab-pages', excludes: ['@pages.tmp']) }

    it 'prepends a leading dot slash to tar excludes' do
      expect(subject.exclude_dirs(:tar)).to eq(['--exclude=lost+found', '--exclude=./@pages.tmp'])
    end

    it 'prepends a leading slash and app_files_dir basename to rsync excludes' do
      expect(subject.exclude_dirs(:rsync)).to eq(['--exclude=lost+found', '--exclude=/gitlab-pages/@pages.tmp'])
    end
  end

  describe '#run_pipeline!' do
    subject { described_class.new('registry', '/var/gitlab-registry') }

    it 'executes an Open3.pipeline for cmd_list' do
      expect(Open3).to receive(:pipeline).with(%w[whew command], %w[another cmd], any_args)

      subject.run_pipeline!([%w[whew command], %w[another cmd]])
    end

    it 'returns an empty output on success pipeline' do
      expect(subject.run_pipeline!(%w[true true])[1]).to eq('')
    end

    it 'returns the stderr for failed pipeline' do
      expect(
        subject.run_pipeline!(['echo OMG: failed command present 1>&2; false', 'true'])[1]
      ).to match(/OMG: failed/)
    end

    it 'returns the success status list on success pipeline' do
      expect(
        subject.run_pipeline!(%w[true true])[0]
      ).to eq_statuslist([status_0, status_0])
    end

    it 'returns the failed status in status list for failed commands in pipeline' do
      expect(subject.run_pipeline!(%w[false true true])[0]).to eq_statuslist([status_1, status_0, status_0])
      expect(subject.run_pipeline!(%w[true false true])[0]).to eq_statuslist([status_0, status_1, status_0])
      expect(subject.run_pipeline!(%w[false false true])[0]).to eq_statuslist([status_1, status_1, status_0])
      expect(subject.run_pipeline!(%w[false true false])[0]).to eq_statuslist([status_1, status_0, status_1])
      expect(subject.run_pipeline!(%w[false false false])[0]).to eq_statuslist([status_1, status_1, status_1])
    end
  end

  describe '#pipeline_succeeded?' do
    subject { described_class.new('registry', '/var/gitlab-registry') }

    it 'returns true if both tar and gzip succeeeded' do
      expect(
        subject.pipeline_succeeded?(tar_status: status_0, gzip_status: status_0, output: 'any_output')
      ).to be_truthy
    end

    it 'returns false if gzip failed' do
      expect(
        subject.pipeline_succeeded?(tar_status: status_1, gzip_status: status_1, output: 'any_output')
      ).to be_falsey
    end

    context 'if gzip succeeded and tar failed non-critically' do
      before do
        allow(subject).to receive(:tar_ignore_non_success?).and_return(true)
      end

      it 'returns true' do
        expect(
          subject.pipeline_succeeded?(tar_status: status_1, gzip_status: status_0, output: 'any_output')
        ).to be_truthy
      end
    end

    context 'if gzip succeeded and tar failed in other cases' do
      before do
        allow(subject).to receive(:tar_ignore_non_success?).and_return(false)
      end

      it 'returns false' do
        expect(
          subject.pipeline_succeeded?(tar_status: status_1, gzip_status: status_0, output: 'any_output')
        ).to be_falsey
      end
    end
  end

  describe '#tar_ignore_non_success?' do
    subject { described_class.new('registry', '/var/gitlab-registry') }

    context 'if `tar` command exits with 1 exitstatus' do
      it 'returns true' do
        expect(
          subject.tar_ignore_non_success?(1, 'any_output')
        ).to be_truthy
      end

      it 'outputs a warning' do
        expect do
          subject.tar_ignore_non_success?(1, 'any_output')
        end.to output(/Ignoring tar exit status 1/).to_stdout
      end
    end

    context 'if `tar` command exits with 2 exitstatus with non-critical warning' do
      before do
        allow(subject).to receive(:noncritical_warning?).and_return(true)
      end

      it 'returns true' do
        expect(
          subject.tar_ignore_non_success?(2, 'any_output')
        ).to be_truthy
      end

      it 'outputs a warning' do
        expect do
          subject.tar_ignore_non_success?(2, 'any_output')
        end.to output(/Ignoring non-success exit status/).to_stdout
      end
    end

    context 'if `tar` command exits with any other unlisted error' do
      before do
        allow(subject).to receive(:noncritical_warning?).and_return(false)
      end

      it 'returns false' do
        expect(
          subject.tar_ignore_non_success?(2, 'any_output')
        ).to be_falsey
      end
    end
  end

  describe '#noncritical_warning?' do
    subject { described_class.new('registry', '/var/gitlab-registry') }

    it 'returns true if given text matches noncritical warnings list' do
      expect(
        subject.noncritical_warning?('tar: .: Cannot mkdir: No such file or directory')
      ).to be_truthy

      expect(
        subject.noncritical_warning?('gtar: .: Cannot mkdir: No such file or directory')
      ).to be_truthy
    end

    it 'returns false otherwize' do
      expect(
        subject.noncritical_warning?('unknown message')
      ).to be_falsey
    end
  end
end
