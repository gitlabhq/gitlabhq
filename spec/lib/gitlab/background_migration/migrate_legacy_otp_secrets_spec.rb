# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateLegacyOtpSecrets, feature_category: :system_access do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:users) { table(:users) }
  let(:migration) do
    described_class.new(
      start_id: users.minimum(:id),
      end_id: users.maximum(:id),
      batch_table: :users,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    )
  end

  describe '#perform' do
    let!(:user_with_legacy_otp) do
      users.create!(
        name: generate(:name),
        username: 'user_with_legacy_otp',
        email: generate(:email),
        otp_required_for_login: true,
        organization_id: organization.id,
        projects_limit: 0
      )
    end

    let!(:user_with_new_otp) do
      users.create!(
        name: generate(:name),
        username: 'user_with_new_otp',
        email: generate(:email),
        otp_required_for_login: true,
        organization_id: organization.id,
        projects_limit: 0,
        otp_secret: User.generate_otp_secret(32)
      )
    end

    let!(:user_without_otp) do
      users.create!(
        name: generate(:name),
        username: 'user_without_otp',
        email: generate(:email),
        otp_required_for_login: false,
        organization_id: organization.id,
        projects_limit: 0,
        encrypted_otp_secret: nil,
        encrypted_otp_secret_iv: nil,
        encrypted_otp_secret_salt: nil,
        otp_secret: nil
      )
    end

    before do
      legacy_otp_user = User.find(user_with_legacy_otp.id)
      legacy_otp_user.update_attribute(:otp_secret, User.generate_otp_secret(32))
      legacy_otp_user.update_column(:otp_secret, nil)
    end

    it 'processes all users in the batch' do
      expect { migration.perform }.not_to raise_error
    end

    it 'updates users with legacy otp' do
      expect { migration.perform }.to change { user_with_legacy_otp.reload[:otp_secret] }
    end

    it 'does not modify users with new otp' do
      expect { migration.perform }.not_to change { user_with_new_otp.reload[:otp_secret] }
    end

    it 'does not modify users without OTP secrets' do
      expect { migration.perform }.not_to change { user_without_otp.reload[:otp_secret] }
    end

    context 'with sub-batching' do
      it 'processes users in sub-batches' do
        expect(migration).to receive(:each_sub_batch).and_call_original
        migration.perform
      end
    end

    context 'when a user has an undecryptable legacy secret' do
      let!(:user_with_corrupted_otp) do
        users.create!(
          name: generate(:name),
          username: 'user_with_corrupted_otp',
          email: generate(:email),
          otp_required_for_login: true,
          organization_id: organization.id,
          projects_limit: 0,
          encrypted_otp_secret: 'not-a-valid-cipher-text',
          encrypted_otp_secret_iv: Base64.strict_encode64('0' * 16),
          encrypted_otp_secret_salt: Base64.strict_encode64('salt')
        )
      end

      it 'logs the failure, skips the user, and does not raise' do
        expect(Gitlab::BackgroundMigration::Logger).to receive(:error).with(
          hash_including(
            message: 'Failed to migrate OTP secret for user',
            Labkit::Fields::GL_USER_ID => user_with_corrupted_otp.id
          )
        )

        expect { migration.perform }.not_to raise_error
        expect(user_with_corrupted_otp.reload[:otp_secret]).to be_nil
      end

      it 'still migrates the other users in the same sub-batch' do
        allow(Gitlab::BackgroundMigration::Logger).to receive(:error)

        expect { migration.perform }.to change { user_with_legacy_otp.reload[:otp_secret] }
      end
    end
  end

  describe 'migration metadata' do
    it 'has the correct operation name' do
      expect(migration.operation_name).to eq(:set_otp_secret)
    end

    it 'has the correct feature category' do
      expect(described_class.feature_category).to eq(:system_access)
    end
  end
end
