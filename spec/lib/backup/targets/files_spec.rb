# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Targets::Files, feature_category: :backup_restore do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project) }
  let(:backup_options) { Backup::Options.new }
  let(:backup_basepath) { Pathname(Gitlab.config.backup.path) }

  let(:status_0) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:status_1) { instance_double(Process::Status, success?: false, exitstatus: 1) }
  let(:pipeline_status_success) { Gitlab::Backup::Cli::Shell::Pipeline::Result.new(status_list: [status_0, status_0]) }
  let(:pipeline_status_failed) { Gitlab::Backup::Cli::Shell::Pipeline::Result.new(status_list: [status_1, status_1]) }
  let(:tmp_backup_restore_dir) { Dir.mktmpdir('files-target-restore') }
  let(:restore_target) { File.realpath(tmp_backup_restore_dir) }
  let(:backup_target) do
    %w[@pages.tmp lost+found @hashed].each do |folder|
      path = Pathname(tmp_backup_restore_dir).join(folder, 'something', 'else')

      FileUtils.mkdir_p(path)
      FileUtils.touch(path.join('artifacts.zip'))
    end

    File.realpath(tmp_backup_restore_dir)
  end

  before do
    allow(FileUtils).to receive(:mv).and_return(true)
    allow(File).to receive(:exist?).and_return(true)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:progress).and_return(progress)
    end
  end

  after do
    FileUtils.rm_rf([restore_target, backup_target], secure: true)
  end

  describe '#restore' do
    subject(:files) { described_class.new(progress, restore_target, options: backup_options) }

    let(:timestamp) { Time.utc(2017, 3, 22) }

    around do |example|
      travel_to(timestamp) { example.run }
    end

    describe 'folders with permission' do
      let(:existing_content) { File.join(restore_target, 'sample1') }

      before do
        FileUtils.touch(existing_content)
      end

      it 'moves all necessary files' do
        expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
          expect(pipeline).to receive(:run!).and_return(pipeline_status_success)
        end

        tmp_dir = backup_basepath.join('tmp', "registry.#{Time.now.to_i}")
        expect(FileUtils).to receive(:mv).with([existing_content], tmp_dir)

        files.restore('registry.tar.gz', 'backup_id')
      end

      it 'raises no errors' do
        expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
          expect(pipeline).to receive(:run!).and_return(pipeline_status_success)
        end

        expect { files.restore('registry.tar.gz', 'backup_id') }.not_to raise_error
      end

      it 'calls tar command with unlink' do
        expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
          tar_cmd = pipeline.shell_commands[1]

          expect(tar_cmd.cmd_args).to include('--unlink-first')
          expect(tar_cmd.cmd_args).to include('--recursive-unlink')

          expect(pipeline).to receive(:run!).and_return(pipeline_status_success)
        end

        files.restore('registry.tar.gz', 'backup_id')
      end

      it 'raises an error on failure' do
        expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
          expect(pipeline).to receive(:run!).and_return(pipeline_status_failed)
        end

        expect { files.restore('registry.tar.gz', 'backup_id') }.to raise_error(/Restore operation failed:/)
      end
    end

    describe 'folders without permissions' do
      before do
        FileUtils.touch('registry.tar.gz')
        allow(FileUtils).to receive(:mv).and_raise(Errno::EACCES)
        allow(files).to receive(:run!).and_return([[true, true], ''])
        allow(files).to receive(:pipeline_succeeded?).and_return(true)
      end

      after do
        FileUtils.rm_rf('registry.tar.gz')
      end

      it 'shows error message' do
        expect(files).to receive(:access_denied_error).with(restore_target)

        files.restore('registry.tar.gz', 'backup_id')
      end
    end

    describe 'folders that are a mountpoint' do
      before do
        allow(FileUtils).to receive(:mv).and_raise(Errno::EBUSY)
        allow(files).to receive(:run!).and_return([[true, true], ''])
        allow(files).to receive(:pipeline_succeeded?).and_return(true)
      end

      it 'shows error message' do
        expect(files).to receive(:resource_busy_error).with(restore_target)
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
        expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
          decompress_cmd = pipeline.shell_commands[0]

          expect(decompress_cmd.cmd_args).to include('tee')
          expect(pipeline).to receive(:run!).and_return(pipeline_status_success)
        end

        expect do
          files.restore('registry.tar.gz', 'backup_id')
        end.to output(/Using custom DECOMPRESS_CMD 'tee'/).to_stdout
      end
    end
  end

  describe '#dump' do
    subject(:files) do
      described_class.new(progress, backup_target, excludes: ['@pages.tmp'], options: backup_options)
    end

    it 'raises no errors' do
      expect { files.dump('registry.tar.gz', 'backup_id') }.not_to raise_error
    end

    it 'excludes tmp dirs from archive' do
      expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
        tar_cmd = pipeline.shell_commands[0]

        expect(tar_cmd.cmd_args).to include('--exclude=lost+found')
        expect(tar_cmd.cmd_args).to include('--exclude=./@pages.tmp')

        allow(pipeline).to receive(:run!).and_call_original
      end

      files.dump('registry.tar.gz', 'backup_id')
    end

    it 'raises an error on failure' do
      expect(files).to receive(:pipeline_succeeded?).and_return(false)

      expect do
        files.dump('registry.tar.gz', 'backup_id')
      end.to raise_error(/Failed to create compressed file/)
    end

    describe 'with Backup::Options.strategy = copy' do
      let(:backup_options) { create(:backup_options, :strategy_copy) }
      let(:backup_basename) { File.basename(backup_target) }
      let(:backup_basepath) { files.send(:backup_basepath) }

      before do
        allow(files).to receive(:pipeline_succeeded?).and_return(true)
      end

      it 'excludes tmp dirs from rsync' do
        cmd_args = %W[rsync -a --delete --exclude=lost+found --exclude=/#{backup_basename}/@pages.tmp
          #{backup_target} #{backup_basepath}]

        expect(Gitlab::Popen).to receive(:popen).with(cmd_args).and_return(['', 0])

        files.dump('registry.tar.gz', 'backup_id')
      end

      it 'retries if rsync fails due to vanishing files' do
        cmd_args = %W[rsync -a --delete --exclude=lost+found --exclude=/#{backup_basename}/@pages.tmp
          #{backup_target} #{backup_basepath}]
        expect(Gitlab::Popen).to receive(:popen).with(cmd_args).and_return(['rsync failed', 24], ['', 0])

        expect do
          files.dump('registry.tar.gz', 'backup_id')
        end.to output(/files vanished during rsync, retrying/).to_stdout
      end

      it 'raises an error and outputs an error message if rsync failed' do
        cmd_args = %W[rsync -a --delete --exclude=lost+found --exclude=/#{backup_basename}/@pages.tmp
          #{backup_target} #{backup_basepath}]
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
        expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
          compress_cmd = pipeline.shell_commands[1]

          expect(compress_cmd.cmd_args).to include('tee')
        end

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
        expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
          compress_cmd = pipeline.shell_commands[1]

          expect(compress_cmd.cmd_args).to include('gzip --rsyncable -c -1')
        end

        files.dump('registry.tar.gz', 'backup_id')
      end
    end

    context 'when GZIP_RSYNCABLE is not set' do
      it 'gzips the files without the rsyncable option' do
        expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
          compress_cmd = pipeline.shell_commands[1]

          expect(compress_cmd.cmd_args).to include('gzip -c -1')
        end

        files.dump('registry.tar.gz', 'backup_id')
      end
    end
  end

  describe '#exclude_dirs_rsync' do
    subject(:files) do
      described_class.new(progress, backup_target, excludes: ['@pages.tmp'], options: backup_options)
    end

    it 'prepends a leading slash and app_files_dir basename to rsync excludes' do
      basefolder = File.basename(backup_target)

      expect(files.exclude_dirs_rsync).to eq(%W[--exclude=lost+found --exclude=/#{basefolder}/@pages.tmp])
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

  context 'with unified backup' do
    subject(:files) do
      described_class.new(progress, '/fake/path', options: backup_options)
    end

    it 'is not asynchronous by default' do
      expect(files.asynchronous?).to be_falsey
    end
  end
end
