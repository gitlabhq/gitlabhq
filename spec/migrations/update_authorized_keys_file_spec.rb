require 'spec_helper'
require Rails.root.join('db', 'migrate', '20170626202753_update_authorized_keys_file.rb')

describe UpdateAuthorizedKeysFile, :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    context 'when authorized_keys_enabled is nil' do
      before do
        # Ensure the column can be null for the test
        ActiveRecord::Base.connection.change_column_null :application_settings, :authorized_keys_enabled, true
        ActiveRecord::Base.connection.change_column :application_settings, :authorized_keys_enabled, :boolean, default: nil

        ApplicationSetting.create!(authorized_keys_enabled: nil)
      end

      it 'sets authorized_keys_enabled to true' do
        migration.up

        expect(ApplicationSetting.last.authorized_keys_enabled).to be_truthy
      end

      context 'there are keys created before and after the cutoff datetime' do
        before do
          Timecop.freeze
        end
        after do
          Timecop.return
        end

        before do
          @cutoff_datetime = UpdateAuthorizedKeysFile::DATETIME_9_3_0_RELEASED
          @keys = []
          Timecop.travel(@cutoff_datetime - 1.day)
          2.times { @keys << create(:key) } # 2 keys before cutoff
          Timecop.travel(@cutoff_datetime + 1.day)
          2.times { @keys << create(:key) } # 2 keys after cutoff
        end

        it 'adds the keys created after the cutoff datetime to the authorized_keys file' do
          Gitlab::Shell.new.remove_all_keys

          migration.up

          file = File.read(Rails.root.join('tmp/tests/.ssh/authorized_keys'))
          expect(file.scan(/ssh-rsa/).count).to eq(2)

          expect(file).not_to include(Gitlab::Shell.strip_key(@keys[0].key))
          expect(file).not_to include(Gitlab::Shell.strip_key(@keys[1].key))
          expect(file).to include(Gitlab::Shell.strip_key(@keys[2].key))
          expect(file).to include(Gitlab::Shell.strip_key(@keys[3].key))
        end
      end

      context 'when an SSH key exists in authorized_keys but not in the DB' do
        before do
          @key_to_stay = create(:key)
          @key_to_delete = create(:key)
          @key_to_delete.delete
        end

        it 'deletes the SSH key from authorized_keys' do
          file = File.read(Rails.root.join('tmp/tests/.ssh/authorized_keys'))
          expect(file).to include(Gitlab::Shell.strip_key(@key_to_stay.key))
          expect(file).to include(Gitlab::Shell.strip_key(@key_to_delete.key))

          migration.up

          file = File.read(Rails.root.join('tmp/tests/.ssh/authorized_keys'))
          expect(file).to include(Gitlab::Shell.strip_key(@key_to_stay.key))
          expect(file).not_to include(Gitlab::Shell.strip_key(@key_to_delete.key))
        end
      end
    end
  end

  describe '#authorized_keys_file_in_use_and_stale?' do
    subject { migration.authorized_keys_file_in_use_and_stale? }

    context 'when the customer ran the broken migration' do
      before do
        allow(migration).to receive(:ran_broken_migration?).and_return(true)
      end

      context 'when is a record in application_settings table' do
        before do
          ApplicationSetting.create!(authorized_keys_enabled: true)
        end

        context 'when authorized_keys_enabled is true' do
          it { is_expected.to be_truthy }
        end

        context 'when authorized_keys_enabled is nil' do
          before do
            # Ensure the column can be null for the test
            ActiveRecord::Base.connection.change_column_null :application_settings, :authorized_keys_enabled, true
            ActiveRecord::Base.connection.change_column :application_settings, :authorized_keys_enabled, :boolean, default: nil

            ApplicationSetting.first.update(authorized_keys_enabled: nil, mirror_max_delay: 300)
          end

          it { is_expected.to be_truthy }
        end

        context 'when authorized_keys_enabled is explicitly false' do
          before do
            ApplicationSetting.first.update!(authorized_keys_enabled: false, mirror_max_delay: 300)
          end

          it { is_expected.to be_falsey }

          it 'outputs a warning message for users who unintentionally Saved the setting unchecked' do
            expect{ subject }.to output(/warning.*intentionally/mi).to_stdout
          end
        end
      end

      context 'when there is no record in application_settings table' do
        before do
          expect(ApplicationSetting.count).to eq(0)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when the customer did not run the broken migration' do
      before do
        allow(migration).to receive(:ran_broken_migration?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#ran_broken_migration?' do
    subject { migration.ran_broken_migration? }

    context 'for unaffected customers: the authorized_keys_enabled column has a default (so the fixed migration ran)' do
      before do
        ActiveRecord::Base.connection.change_column :application_settings, :authorized_keys_enabled, :boolean, default: true
        ActiveRecord::Base.connection.change_column_null :application_settings, :authorized_keys_enabled, false, true
      end

      it 'returns false' do
        expect(subject).to be_falsey
      end
    end

    context 'for affected customers: the authorized_keys_enabled column does not have a default (so the broken migration ran)' do
      before do
        ActiveRecord::Base.connection.change_column_null :application_settings, :authorized_keys_enabled, true
        ActiveRecord::Base.connection.change_column :application_settings, :authorized_keys_enabled, :boolean, default: nil
      end

      it 'returns true' do
        expect(subject).to be_truthy
      end
    end
  end
end
