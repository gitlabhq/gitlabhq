require 'spec_helper'

describe Gitlab::BackgroundMigration::UpdateAuthorizedKeysFileSince do
  let(:background_migration) { described_class.new }

  describe '#perform' do
    let!(:cutoff_datetime) { DateTime.now }

    subject { background_migration.perform(cutoff_datetime) }

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

      it 'calls batch_add_keys_in_db_starting_from with the start key ID' do
        expect(background_migration).to receive(:batch_add_keys_in_db_starting_from).with(@key.id)
        subject
      end
    end

    it 'calls remove_keys_not_found_in_db on Gitlab::Shell' do
      expect_any_instance_of(Gitlab::Shell).to receive(:remove_keys_not_found_in_db)
      subject
    end
  end

  describe '#add_keys_since' do
    let!(:cutoff_datetime) { DateTime.now }

    subject { background_migration.add_keys_since(cutoff_datetime) }

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
        create(:key) # other key
      end

      it 'calls batch_add_keys_in_db_starting_from with the start key ID' do
        expect(background_migration).to receive(:batch_add_keys_in_db_starting_from).with(@key.id)
        subject
      end
    end

    context 'when an SSH key was not created after the cutoff datetime' do
      it 'does not call batch_add_keys_in_db_starting_from' do
        expect(background_migration).not_to receive(:batch_add_keys_in_db_starting_from)
        subject
      end
    end
  end

  describe '#remove_keys_not_found_in_db' do
    it 'calls remove_keys_not_found_in_db on Gitlab::Shell' do
      expect_any_instance_of(Gitlab::Shell).to receive(:remove_keys_not_found_in_db)
      background_migration.remove_keys_not_found_in_db
    end
  end

  describe '#batch_add_keys_in_db_starting_from' do
    context 'when there are many keys in the DB' do
      before do
        @keys = []
        10.times do
          @keys << create(:key)
        end
      end

      it 'adds all the keys in the DB, starting from the given ID, to the authorized_keys file' do
        Gitlab::Shell.new.remove_all_keys

        background_migration.batch_add_keys_in_db_starting_from(@keys[3].id)

        file = File.read(Rails.root.join('tmp/tests/.ssh/authorized_keys'))
        expect(file.scan(/ssh-rsa/).count).to eq(7)

        expect(file).not_to include(Gitlab::Shell.strip_key(@keys[0].key))
        expect(file).not_to include(Gitlab::Shell.strip_key(@keys[2].key))
        expect(file).to include(Gitlab::Shell.strip_key(@keys[3].key))
        expect(file).to include(Gitlab::Shell.strip_key(@keys[9].key))
      end
    end
  end
end
