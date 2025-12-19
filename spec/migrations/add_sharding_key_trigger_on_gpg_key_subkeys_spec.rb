# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddShardingKeyTriggerOnGpgKeySubkeys, feature_category: :source_code_management do
  let(:users) { table(:users) }
  let(:gpg_keys) { table(:gpg_keys) }
  let(:gpg_key_subkeys) { table(:gpg_key_subkeys) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let(:user1) do
    users.create!(email: 'user1@example.com', username: 'user1', projects_limit: 0, organization_id: organization.id)
  end

  let(:user2) do
    users.create!(email: 'user2@example.com', username: 'user2', projects_limit: 0, organization_id: organization.id)
  end

  let(:gpg_key1) { gpg_keys.create!(user_id: user1.id, key: generate_key, fingerprint: generate_fingerprint) }
  let(:gpg_key2) { gpg_keys.create!(user_id: user2.id, key: generate_key, fingerprint: generate_fingerprint) }

  describe '#up' do
    before do
      migrate!
    end

    context 'when inserting new records' do
      it 'automatically sets user_id from the parent gpg_keys table' do
        subkey = gpg_key_subkeys.create!(gpg_key_id: gpg_key1.id, keyid: generate_keyid,
          fingerprint: generate_fingerprint)

        expect(subkey.reload.user_id).to eq(user1.id)
      end

      it 'sets correct user_id for different gpg_keys' do
        subkey1 = gpg_key_subkeys.create!(gpg_key_id: gpg_key1.id, keyid: generate_keyid,
          fingerprint: generate_fingerprint)
        subkey2 = gpg_key_subkeys.create!(gpg_key_id: gpg_key2.id, keyid: generate_keyid,
          fingerprint: generate_fingerprint)

        expect(subkey1.reload.user_id).to eq(user1.id)
        expect(subkey2.reload.user_id).to eq(user2.id)
      end
    end

    context 'when updating existing records' do
      it 'sets user_id when updating a record without user_id' do
        ActiveRecord::Base.connection.execute(
          <<~SQL
            DROP TRIGGER IF EXISTS set_user_id_for_gpg_key_subkeys_on_insert_and_update ON gpg_key_subkeys;

            ALTER TABLE gpg_key_subkeys DROP CONSTRAINT IF EXISTS check_f6590fe2c1;
          SQL
        )

        subkey = gpg_key_subkeys.create!(gpg_key_id: gpg_key1.id, keyid: generate_keyid,
          fingerprint: generate_fingerprint, user_id: nil)
        subkey.reload
        expect(subkey.user_id).to be_nil

        ActiveRecord::Base.connection.execute(
          <<~SQL
            ALTER TABLE gpg_key_subkeys ADD CONSTRAINT check_f6590fe2c1 CHECK (user_id IS NOT NULL) NOT VALID;

            CREATE TRIGGER set_user_id_for_gpg_key_subkeys_on_insert_and_update BEFORE INSERT OR UPDATE ON gpg_key_subkeys FOR EACH ROW EXECUTE FUNCTION sync_user_id_from_gpg_keys_table();
          SQL
        )

        # Update the record to trigger the function
        subkey.update!(keyid: generate_keyid)
        subkey.reload

        expect(subkey.user_id).to eq(user1.id)
      end
    end
  end

  private

  def generate_key
    SecureRandom.hex(1000)
  end

  def generate_fingerprint
    SecureRandom.hex(20)
  end

  def generate_keyid
    SecureRandom.hex(8)
  end
end
