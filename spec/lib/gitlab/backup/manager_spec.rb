require 'spec_helper'

describe Backup::Manager, lib: true do
  describe '#remove_old' do
    let(:progress) { StringIO.new }

    let(:files) do
      [
        '1451606400_2016_01_01_gitlab_backup.tar',
        '1451520000_2015_12_31_gitlab_backup.tar',
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
        allow(Gitlab.config.backup).to receive(:keep_time).and_return(1)

        subject.remove_old
      end

      it 'removes matching files with a human-readable timestamp' do
        expect(FileUtils).to have_received(:rm).with(files[1])
        expect(FileUtils).to have_received(:rm).with(files[2])
      end

      it 'removes matching files without a human-readable timestamp' do
        expect(FileUtils).to have_received(:rm).with(files[3])
        expect(FileUtils).to have_received(:rm).with(files[4])
      end

      it 'does not remove files that are not old enough' do
        expect(FileUtils).not_to have_received(:rm).with(files[0])
      end

      it 'does not remove non-matching files' do
        expect(FileUtils).not_to have_received(:rm).with(files[5])
      end

      it 'prints a done message' do
        expect(progress).to have_received(:puts).with('done. (4 removed)')
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
      end

      it 'sets the correct removed count' do
        expect(progress).to have_received(:puts).with('done. (3 removed)')
      end

      it 'prints the error from file that could not be removed' do
        expect(progress).to have_received(:puts).with(a_string_matching(message))
      end
    end
  end
end
