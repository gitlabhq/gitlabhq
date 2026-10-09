# frozen_string_literal: true

require 'fast_spec_helper'
require 'sys/filesystem'

RSpec.describe Backup::Restore::Unpack, feature_category: :backup_restore do
  let(:backup_path) { Pathname(Dir.mktmpdir('backup unpack ')) }
  let(:manifest_filepath) { backup_path.join('backup_information.yml') }
  let(:backup_id) { nil }
  let(:tar_file) { 'selected_gitlab_backup.tar' }
  let(:options) { Backup::Options.new }
  let(:logger) { instance_double(Gitlab::BackupLogger, info: nil, warn: nil, error: nil) }
  let(:available_bytes) { 6000 }
  let(:stat) { instance_double(Sys::Filesystem::Stat, bytes_available: available_bytes) }

  subject(:unpack) do
    described_class.new(backup_id: backup_id, backup_path: backup_path,
      manifest_filepath: manifest_filepath, options: options, logger: logger)
  end

  before do
    File.write(backup_path.join(tar_file), 'a' * 2000)
    allow(Kernel).to receive(:system).and_return(true)
    allow(Sys::Filesystem).to receive(:stat).with(backup_path.to_s).and_return(stat)
  end

  after do
    FileUtils.remove_entry(backup_path)
  end

  describe '#run!' do
    subject(:run_unpack) { unpack.run!(check_disk_space: true) }

    shared_examples 'stops before unpacking' do
      it 'exits with status 1 without running tar', :aggregate_failures do
        expect(Kernel).not_to receive(:system)

        expect { run_unpack }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    context 'with insufficient space' do
      where(:available_bytes) { [0, 5999] }

      with_them do
        it_behaves_like 'stops before unpacking'

        it 'reports the destination, available bytes, estimated requirement, and bypass' do
          available_size = ActiveSupport::NumberHelper.number_to_human_size(available_bytes)
          required_size = ActiveSupport::NumberHelper.number_to_human_size(6000)

          expect(logger).to receive(:error).with(
            "Insufficient disk space in #{backup_path}: #{available_size} (#{available_bytes} bytes) available, " \
              "estimated #{required_size} (6000 bytes) required. " \
              'Set BACKUP_SKIP_STORAGE_CHECK=true to bypass this check.')

          expect { run_unpack }.to raise_error(SystemExit)
        end
      end
    end

    context 'with space at or above the estimated requirement' do
      where(:available_bytes) { [6000, 6001] }

      with_them do
        it 'unpacks the archive on the checked filesystem', :aggregate_failures do
          expect(Sys::Filesystem).to receive(:stat).with(backup_path.to_s).ordered.and_return(stat)
          expect(Kernel).to receive(:system).with('tar', '-xf', tar_file).ordered.and_return(true)

          run_unpack
        end
      end
    end

    context 'with small, fractional GiB, and large sizes' do
      where(:archive_bytes, :available_bytes, :required_bytes) do
        [[1, 2, 3], [2**29, (2**29) + 1, 1610612736], [(2**40) + 2, (2**40) + 1, 3298534883334]]
      end

      with_them do
        before do
          allow(File).to receive(:size).and_call_original
          allow(File).to receive(:size).with(tar_file).and_return(archive_bytes)
        end

        it_behaves_like 'stops before unpacking'

        it 'reports human-readable sizes alongside exact byte counts' do
          available_size = ActiveSupport::NumberHelper.number_to_human_size(available_bytes)
          required_size = ActiveSupport::NumberHelper.number_to_human_size(required_bytes)

          expect(logger).to receive(:error).with(a_string_including(
            "#{available_size} (#{available_bytes} bytes) available",
            "#{required_size} (#{required_bytes} bytes) required"))

          expect { run_unpack }.to raise_error(SystemExit)
        end
      end
    end

    context 'when fragment size differs from block size' do
      let(:stat) do
        Sys::Filesystem::Stat.new.tap do |filesystem|
          filesystem.block_size = 4096
          filesystem.fragment_size = 512
          filesystem.blocks_available = 10
        end
      end

      it_behaves_like 'stops before unpacking'
    end

    context 'when a backup is explicitly selected' do
      let(:backup_id) { 'selected' }
      let(:available_bytes) { 5999 }

      before do
        File.write(backup_path.join('other_gitlab_backup.tar'), 'a')
        FileUtils.touch(manifest_filepath)
      end

      it_behaves_like 'stops before unpacking'
    end

    context 'when the check is bypassed' do
      let(:options) { Backup::Options.new(skip_storage_check: true) }

      it 'warns and unpacks without reading the archive size or filesystem', :aggregate_failures do
        expect(File).not_to receive(:size).with(tar_file)
        expect(Sys::Filesystem).not_to receive(:stat)
        expect(logger).to receive(:warn).with(a_string_including('Skipping disk space check'))
        expect(Kernel).to receive(:system).with('tar', '-xf', tar_file).and_return(true)

        run_unpack
      end

      context 'when tar fails' do
        before do
          allow(Kernel).to receive(:system).and_return(false)
        end

        it 'preserves the unpack failure', :aggregate_failures do
          expect(logger).to receive(:error).with(a_string_including('Unpacking backup failed'))

          expect { run_unpack }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        end
      end
    end

    context 'when filesystem statistics cannot be read' do
      before do
        allow(Sys::Filesystem).to receive(:stat).and_raise(Sys::Filesystem::Error, 'stat failed')
      end

      it_behaves_like 'stops before unpacking'

      it 'distinguishes an unavailable check from insufficient space' do
        expect(logger).to receive(:error).with(a_string_including(
          "Unable to check disk space in #{backup_path}", 'stat failed', 'BACKUP_SKIP_STORAGE_CHECK=true'))

        expect { run_unpack }.to raise_error(SystemExit)
      end
    end

    context 'when the archive size cannot be read' do
      before do
        allow(File).to receive(:size).and_call_original
        allow(File).to receive(:size).with(tar_file).and_raise(Errno::EACCES)
      end

      it_behaves_like 'stops before unpacking'

      it 'reports the failed check' do
        expect(logger).to receive(:error).with(a_string_including(
          'Unable to check disk space', 'Permission denied'))

        expect { run_unpack }.to raise_error(SystemExit)
      end
    end

    context 'when disk space checking is not requested' do
      it 'unpacks without accessing storage statistics', :aggregate_failures do
        expect(File).not_to receive(:size).with(tar_file)
        expect(Sys::Filesystem).not_to receive(:stat)
        expect(Kernel).to receive(:system).with('tar', '-xf', tar_file).and_return(true)

        unpack.run!
      end
    end
  end
end
