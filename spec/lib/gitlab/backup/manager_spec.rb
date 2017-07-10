require 'spec_helper'

describe Backup::Manager do
  include StubENV

  let(:progress) { StringIO.new }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)

    allow_any_instance_of(String).to receive(:color) do |string, _color|
      string
    end

    @old_progress = $progress # rubocop:disable Style/GlobalVars
    $progress = progress # rubocop:disable Style/GlobalVars
  end

  after do
    $progress = @old_progress # rubocop:disable Style/GlobalVars
  end

  describe '#remove_old' do
    let(:files) do
      [
        '1451606400_2016_01_01_1.2.3_gitlab_backup.tar',
        '1451520000_2015_12_31_4.5.6_gitlab_backup.tar',
        '1451510000_2015_12_30_gitlab_backup.tar',
        '1450742400_2015_12_22_gitlab_backup.tar',
        '1449878400_gitlab_backup.tar',
        '1449014400_gitlab_backup.tar',
        'manual_gitlab_backup.tar'
      ]
    end

    before do
      allow(Dir).to receive(:chdir).and_yield
      allow(Dir).to receive(:glob).and_return(files)
      allow(FileUtils).to receive(:rm)
      allow(Time).to receive(:now).and_return(Time.utc(2016))
    end

    context 'when keep_time is zero' do
      before do
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(0)

        subject.remove_old
      end

      it 'removes no files' do
        expect(FileUtils).not_to have_received(:rm)
      end

      it 'prints a skipped message' do
        expect(progress).to have_received(:puts).with('skipping')
      end
    end

    context 'when there are no files older than keep_time' do
      before do
        # Set to 30 days
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(2592000)

        subject.remove_old
      end

      it 'removes no files' do
        expect(FileUtils).not_to have_received(:rm)
      end

      it 'prints a done message' do
        expect(progress).to have_received(:puts).with('done. (0 removed)')
      end
    end

    context 'when keep_time is set to remove files' do
      before do
        # Set to 1 second
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(1)

        subject.remove_old
      end

      it 'removes matching files with a human-readable versioned timestamp' do
        expect(FileUtils).to have_received(:rm).with(files[1])
      end

      it 'removes matching files with a human-readable non-versioned timestamp' do
        expect(FileUtils).to have_received(:rm).with(files[2])
        expect(FileUtils).to have_received(:rm).with(files[3])
      end

      it 'removes matching files without a human-readable timestamp' do
        expect(FileUtils).to have_received(:rm).with(files[4])
        expect(FileUtils).to have_received(:rm).with(files[5])
      end

      it 'does not remove files that are not old enough' do
        expect(FileUtils).not_to have_received(:rm).with(files[0])
      end

      it 'does not remove non-matching files' do
        expect(FileUtils).not_to have_received(:rm).with(files[6])
      end

      it 'prints a done message' do
        expect(progress).to have_received(:puts).with('done. (5 removed)')
      end
    end

    context 'when removing a file fails' do
      let(:file) { files[1] }
      let(:message) { "Permission denied @ unlink_internal - #{file}" }

      before do
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(1)
        allow(FileUtils).to receive(:rm).with(file).and_raise(Errno::EACCES, message)

        subject.remove_old
      end

      it 'removes the remaining expected files' do
        expect(FileUtils).to have_received(:rm).with(files[2])
        expect(FileUtils).to have_received(:rm).with(files[3])
        expect(FileUtils).to have_received(:rm).with(files[4])
        expect(FileUtils).to have_received(:rm).with(files[5])
      end

      it 'sets the correct removed count' do
        expect(progress).to have_received(:puts).with('done. (4 removed)')
      end

      it 'prints the error from file that could not be removed' do
        expect(progress).to have_received(:puts).with(a_string_matching(message))
      end
    end
  end

  describe '#unpack' do
    before do
      allow(Dir).to receive(:chdir)
    end

    context 'when there are no backup files in the directory' do
      before do
        allow(Dir).to receive(:glob).and_return([])
      end

      it 'fails the operation and prints an error' do
        expect { subject.unpack }.to raise_error SystemExit
        expect(progress).to have_received(:puts)
          .with(a_string_matching('No backups found'))
      end
    end

    context 'when there are two backup files in the directory and BACKUP variable is not set' do
      before do
        allow(Dir).to receive(:glob).and_return(
          [
            '1451606400_2016_01_01_1.2.3_gitlab_backup.tar',
            '1451520000_2015_12_31_gitlab_backup.tar'
          ]
        )
      end

      it 'fails the operation and prints an error' do
        expect { subject.unpack }.to raise_error SystemExit
        expect(progress).to have_received(:puts)
          .with(a_string_matching('Found more than one backup'))
      end
    end

    context 'when BACKUP variable is set to a non-existing file' do
      before do
        allow(Dir).to receive(:glob).and_return(
          [
            '1451606400_2016_01_01_gitlab_backup.tar'
          ]
        )
        allow(File).to receive(:exist?).and_return(false)

        stub_env('BACKUP', 'wrong')
      end

      it 'fails the operation and prints an error' do
        expect { subject.unpack }.to raise_error SystemExit
        expect(File).to have_received(:exist?).with('wrong_gitlab_backup.tar')
        expect(progress).to have_received(:puts)
          .with(a_string_matching('The backup file wrong_gitlab_backup.tar does not exist'))
      end
    end

    context 'when BACKUP variable is set to a correct file' do
      before do
        allow(Dir).to receive(:glob).and_return(
          [
            '1451606400_2016_01_01_1.2.3_gitlab_backup.tar'
          ]
        )
        allow(File).to receive(:exist?).and_return(true)
        allow(Kernel).to receive(:system).and_return(true)
        allow(YAML).to receive(:load_file).and_return(gitlab_version: Gitlab::VERSION)

        stub_env('BACKUP', '1451606400_2016_01_01_1.2.3')
      end

      it 'unpacks the file' do
        subject.unpack

        expect(Kernel).to have_received(:system)
          .with("tar", "-xf", "1451606400_2016_01_01_1.2.3_gitlab_backup.tar")
        expect(progress).to have_received(:puts).with(a_string_matching('done'))
      end
    end
  end
end
