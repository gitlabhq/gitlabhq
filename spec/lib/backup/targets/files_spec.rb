# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Targets::Files, feature_category: :backup_restore do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project) }
  let(:backup_options) { Backup::Options.new }
  let(:backup_basepath) { Pathname(Gitlab.config.backup.path) }

  let(:status_0) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:status_1) { instance_double(Process::Status, success?: false, exitstatus: 1) }
  let(:status_2) { instance_double(Process::Status, success?: false, exitstatus: 2) }

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

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:progress).and_return(progress)
    end
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
    subject(:files) { described_class.new(progress, '/var/gitlab-registry', options: backup_options) }

    let(:timestamp) { Time.utc(2017, 3, 22) }

    around do |example|
      travel_to(timestamp) { example.run }
    end

    describe 'folders with permission' do
      before do
        allow(files).to receive(:run_pipeline!).and_return([[true, true], ''])
        allow(files).to receive(:backup_existing_files).and_return(true)
        allow(files).to receive(:pipeline_succeeded?).and_return(true)
        found_files = %w[/var/gitlab-registry/. /var/gitlab-registry/.. /var/gitlab-registry/sample1]
        allow(Dir).to receive(:glob).with("/var/gitlab-registry/*", File::FNM_DOTMATCH).and_return(found_files)
      end

      it 'moves all necessary files' do
        allow(files).to receive(:backup_existing_files).and_call_original

        tmp_dir = backup_basepath.join('tmp', "registry.#{Time.now.to_i}")
        expect(FileUtils).to receive(:mv).with(['/var/gitlab-registry/sample1'], tmp_dir)

        files.restore('registry.tar.gz', 'backup_id')
      end

      it 'raises no errors' do
        expect { files.restore('registry.tar.gz', 'backup_id') }.not_to raise_error
      end

      it 'calls tar command with unlink' do
        expect(files).to receive(:tar).and_return('blabla-tar')

        expect(files).to receive(:run_pipeline!).with(
          ['gzip -cd', %w[blabla-tar --unlink-first --recursive-unlink -C /var/gitlab-registry -xf -]],
          any_args)
        expect(files).to receive(:pipeline_succeeded?).and_return(true)

        files.restore('registry.tar.gz', 'backup_id')
      end

      it 'raises an error on failure' do
        expect(files).to receive(:pipeline_succeeded?).and_return(false)

        expect { files.restore('registry.tar.gz', 'backup_id') }.to raise_error(/Restore operation failed:/)
      end
    end

    describe 'folders without permissions' do
      before do
        allow(FileUtils).to receive(:mv).and_raise(Errno::EACCES)
        allow(files).to receive(:run_pipeline!).and_return([[true, true], ''])
        allow(files).to receive(:pipeline_succeeded?).and_return(true)
      end

      it 'shows error message' do
        expect(files).to receive(:access_denied_error).with("/var/gitlab-registry")

        files.restore('registry.tar.gz', 'backup_id')
      end
    end

    describe 'folders that are a mountpoint' do
      before do
        allow(FileUtils).to receive(:mv).and_raise(Errno::EBUSY)
        allow(files).to receive(:run_pipeline!).and_return([[true, true], ''])
        allow(files).to receive(:pipeline_succeeded?).and_return(true)
      end

      it 'shows error message' do
        expect(files).to receive(:resource_busy_error).with("/var/gitlab-registry")
                             .and_call_original

        expect { files.restore('registry.tar.gz', 'backup_id') }.to raise_error(/is a mountpoint/)
      end
    end

    describe 'with DECOMPRESS_CMD' do
      before do
        stub_env('DECOMPRESS_CMD', 'tee')
        allow(files).to receive(:pipeline_succeeded?).and_return(true)
      end

      it 'passes through tee instead of gzip' do
        expect(files).to receive(:run_pipeline!).with(['tee', anything], any_args).and_return([[true, true], ''])

        expect do
          files.restore('registry.tar.gz', 'backup_id')
        end.to output(/Using custom DECOMPRESS_CMD 'tee'/).to_stdout
      end
    end
  end

  describe '#dump' do
    subject(:files) do
      described_class.new(progress, '/var/gitlab-pages', excludes: ['@pages.tmp'], options: backup_options)
    end

    before do
      allow(files).to receive(:run_pipeline!).and_return([[true, true], ''])
      allow(files).to receive(:pipeline_succeeded?).and_return(true)
    end

    it 'raises no errors' do
      expect { files.dump('registry.tar.gz', 'backup_id') }.not_to raise_error
    end

    it 'excludes tmp dirs from archive' do
      expect(files).to receive(:tar).and_return('blabla-tar')

      expect(files).to receive(:run_pipeline!).with(
        [%w[blabla-tar --exclude=lost+found --exclude=./@pages.tmp -C /var/gitlab-pages -cf - .], 'gzip -c -1'],
        any_args)
      files.dump('registry.tar.gz', 'backup_id')
    end

    it 'raises an error on failure' do
      allow(files).to receive(:run_pipeline!).and_return([[true, true], ''])
      expect(files).to receive(:pipeline_succeeded?).and_return(false)

      expect do
        files.dump('registry.tar.gz', 'backup_id')
      end.to raise_error(/Failed to create compressed file/)
    end

    describe 'with STRATEGY=copy' do
      before do
        stub_env('STRATEGY', 'copy')
        allow(files).to receive(:backup_basepath).and_return(Pathname('/var/gitlab-backup'))
        allow(File).to receive(:realpath).with('/var/gitlab-backup').and_return('/var/gitlab-backup')
      end

      it 'excludes tmp dirs from rsync' do
        cmd_args = %w[rsync -a --delete --exclude=lost+found --exclude=/gitlab-pages/@pages.tmp
          /var/gitlab-pages /var/gitlab-backup]
        expect(Gitlab::Popen).to receive(:popen).with(cmd_args).and_return(['', 0])

        files.dump('registry.tar.gz', 'backup_id')
      end

      it 'retries if rsync fails due to vanishing files' do
        cmd_args = %w[rsync -a --delete --exclude=lost+found --exclude=/gitlab-pages/@pages.tmp
          /var/gitlab-pages /var/gitlab-backup]
        expect(Gitlab::Popen).to receive(:popen).with(cmd_args).and_return(['rsync failed', 24], ['', 0])

        expect do
          files.dump('registry.tar.gz', 'backup_id')
        end.to output(/files vanished during rsync, retrying/).to_stdout
      end

      it 'raises an error and outputs an error message if rsync failed' do
        cmd_args = %w[rsync -a --delete --exclude=lost+found --exclude=/gitlab-pages/@pages.tmp
          /var/gitlab-pages /var/gitlab-backup]
        allow(Gitlab::Popen).to receive(:popen).with(cmd_args).and_return(['rsync failed', 1])

        expect do
          files.dump('registry.tar.gz', 'backup_id')
        end.to output(/rsync failed/).to_stdout
           .and raise_error(/Failed to create compressed file/)
      end
    end

    describe 'with COMPRESS_CMD' do
      before do
        stub_env('COMPRESS_CMD', 'tee')
      end

      it 'passes through tee instead of gzip' do
        expect(files).to receive(:run_pipeline!).with([anything, 'tee'], any_args)
        expect do
          files.dump('registry.tar.gz', 'backup_id')
        end.to output(/Using custom COMPRESS_CMD 'tee'/).to_stdout
      end
    end

    context 'when GZIP_RSYNCABLE is "yes"' do
      before do
        stub_env('GZIP_RSYNCABLE', 'yes')
      end

      it 'gzips the files with rsyncable option' do
        expect(files).to receive(:run_pipeline!).with([anything, 'gzip --rsyncable -c -1'], any_args)
        files.dump('registry.tar.gz', 'backup_id')
      end
    end

    context 'when GZIP_RSYNCABLE is not set' do
      it 'gzips the files without the rsyncable option' do
        expect(files).to receive(:run_pipeline!).with([anything, 'gzip -c -1'], any_args)
        files.dump('registry.tar.gz', 'backup_id')
      end
    end
  end

  describe '#exclude_dirs' do
    subject(:files) do
      described_class.new(progress, '/var/gitlab-pages', excludes: ['@pages.tmp'], options: backup_options)
    end

    it 'prepends a leading dot slash to tar excludes' do
      expect(files.exclude_dirs(:tar)).to eq(%w[--exclude=lost+found --exclude=./@pages.tmp])
    end

    it 'prepends a leading slash and app_files_dir basename to rsync excludes' do
      expect(files.exclude_dirs(:rsync)).to eq(%w[--exclude=lost+found --exclude=/gitlab-pages/@pages.tmp])
    end
  end

  describe '#run_pipeline!' do
    subject(:files) do
      described_class.new(progress, '/var/gitlab-registry', options: backup_options)
    end

    it 'executes an Open3.pipeline for cmd_list' do
      expect(Open3).to receive(:pipeline).with(%w[whew command], %w[another cmd], any_args)

      files.run_pipeline!([%w[whew command], %w[another cmd]])
    end

    it 'returns an empty output on success pipeline' do
      expect(files.run_pipeline!(%w[true true])[1]).to eq('')
    end

    it 'returns the stderr for failed pipeline' do
      expect(
        files.run_pipeline!(['echo OMG: failed command present 1>&2; false', 'true'])[1]
      ).to match(/OMG: failed/)
    end

    it 'returns the success status list on success pipeline' do
      expect(
        files.run_pipeline!(%w[true true])[0]
      ).to eq_statuslist([status_0, status_0])
    end

    it 'returns the failed status in status list for failed commands in pipeline' do
      expect(files.run_pipeline!(%w[false true true])[0]).to eq_statuslist([status_1, status_0, status_0])
      expect(files.run_pipeline!(%w[true false true])[0]).to eq_statuslist([status_0, status_1, status_0])
      expect(files.run_pipeline!(%w[false false true])[0]).to eq_statuslist([status_1, status_1, status_0])
      expect(files.run_pipeline!(%w[false true false])[0]).to eq_statuslist([status_1, status_0, status_1])
      expect(files.run_pipeline!(%w[false false false])[0]).to eq_statuslist([status_1, status_1, status_1])
    end
  end

  describe '#pipeline_succeeded?' do
    subject(:files) do
      described_class.new(progress, '/var/gitlab-registry', options: backup_options)
    end

    it 'returns true if both tar and gzip succeeeded' do
      expect(
        files.pipeline_succeeded?(tar_status: status_0, compress_status: status_0, output: 'any_output')
      ).to be_truthy
    end

    it 'returns false if gzip failed' do
      expect(
        files.pipeline_succeeded?(tar_status: status_1, compress_status: status_1, output: 'any_output')
      ).to be_falsey
    end

    context 'if gzip succeeded and tar failed non-critically' do
      before do
        allow(files).to receive(:tar_ignore_non_success?).and_return(true)
      end

      it 'returns true' do
        expect(
          files.pipeline_succeeded?(tar_status: status_1, compress_status: status_0, output: 'any_output')
        ).to be_truthy
      end
    end

    context 'if gzip succeeded and tar failed in other cases' do
      before do
        allow(files).to receive(:tar_ignore_non_success?).and_return(false)
      end

      it 'returns false' do
        expect(
          files.pipeline_succeeded?(tar_status: status_1, compress_status: status_0, output: 'any_output')
        ).to be_falsey
      end
    end
  end

  describe '#tar_ignore_non_success?' do
    subject(:files) do
      described_class.new(progress, '/var/gitlab-registry', options: backup_options)
    end

    context 'if `tar` command exits with 1 exitstatus' do
      it 'returns true' do
        expect(
          files.tar_ignore_non_success?(1, 'any_output')
        ).to be_truthy
      end

      it 'outputs a warning' do
        expect do
          files.tar_ignore_non_success?(1, 'any_output')
        end.to output(/Ignoring tar exit status 1/).to_stdout
      end
    end

    context 'if `tar` command exits with 2 exitstatus with non-critical warning' do
      before do
        allow(files).to receive(:noncritical_warning?).and_return(true)
      end

      it 'returns true' do
        expect(
          files.tar_ignore_non_success?(2, 'any_output')
        ).to be_truthy
      end

      it 'outputs a warning' do
        expect do
          files.tar_ignore_non_success?(2, 'any_output')
        end.to output(/Ignoring non-success exit status/).to_stdout
      end
    end

    context 'if `tar` command exits with any other unlisted error' do
      before do
        allow(files).to receive(:noncritical_warning?).and_return(false)
      end

      it 'returns false' do
        expect(
          files.tar_ignore_non_success?(2, 'any_output')
        ).to be_falsey
      end
    end
  end

  describe '#noncritical_warning?' do
    subject(:files) do
      described_class.new(progress, '/var/gitlab-registry', options: backup_options)
    end

    it 'returns true if given text matches noncritical warnings list' do
      expect(
        files.noncritical_warning?('tar: .: Cannot mkdir: No such file or directory')
      ).to be_truthy

      expect(
        files.noncritical_warning?('gtar: .: Cannot mkdir: No such file or directory')
      ).to be_truthy
    end

    it 'returns false otherwize' do
      expect(
        files.noncritical_warning?('unknown message')
      ).to be_falsey
    end
  end
end
