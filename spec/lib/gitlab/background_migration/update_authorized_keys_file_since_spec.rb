require 'spec_helper'

describe Gitlab::BackgroundMigration::UpdateAuthorizedKeysFileSince do
  describe '#perform' do
    let!(:cutoff_datetime) { DateTime.now }

    subject { described_class.new.perform(cutoff_datetime) }

    context 'when an SSH key was created after the cutoff datetime' do
      before do
        Timecop.freeze
      end
      after do
        Timecop.return
      end

      before do
        Timecop.travel 1.day.from_now
        @key = create(:key)
      end

      it 'queues a batch_add_keys_from call to GitlabShellWorker, including the start key ID' do
        expect(GitlabShellWorker).to receive(:perform_async).with(:batch_add_keys_in_db_starting_from, @key.id)
        allow(GitlabShellWorker).to receive(:perform_async).with(:remove_keys_not_found_in_db)
        subject
      end
    end

    it 'queues a remove_keys_not_found_in_db call to GitlabShellWorker' do
      expect(GitlabShellWorker).to receive(:perform_async).with(:remove_keys_not_found_in_db)
      subject
    end
  end

  describe '#add_keys_since' do
    let!(:cutoff_datetime) { DateTime.now }

    subject { described_class.new.add_keys_since(cutoff_datetime) }

    before do
      Timecop.freeze
    end
    after do
      Timecop.return
    end

    context 'when an SSH key was created after the cutoff datetime' do
      before do
        Timecop.travel 1.day.from_now
        @key = create(:key)
      end

      it 'queues a batch_add_keys_from call to GitlabShellWorker, including the start key ID' do
        expect(GitlabShellWorker).to receive(:perform_async).with(:batch_add_keys_in_db_starting_from, @key.id)
        subject
      end
    end

    context 'when an SSH key was not created after the cutoff datetime' do
      it 'does not use GitlabShellWorker' do
        expect(GitlabShellWorker).not_to receive(:perform_async)
        subject
      end
    end
  end

  describe '#remove_keys_not_found_in_db' do
    it 'queues a rm_keys_not_in_db call to GitlabShellWorker' do
      expect(GitlabShellWorker).to receive(:perform_async).with(:remove_keys_not_found_in_db)
      described_class.new.remove_keys_not_found_in_db
    end
  end
end
