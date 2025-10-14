# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ArchiveRevokedAccessGrants, feature_category: :system_access do
  let(:oauth_access_grants_table) { table(:oauth_access_grants) }
  let(:oauth_access_grant_archived_records_table) { table(:oauth_access_grant_archived_records) }
  let(:oauth_applications_table) { table(:oauth_applications) }
  let(:organizations_table) { table(:organizations) }
  let(:users_table) { table(:users) }

  let!(:organization) { organizations_table.create!(name: 'Test Organization', path: 'test') }
  let!(:user) do
    users_table.create!(name: 'test user', email: 'test@example.com', projects_limit: 1,
      organization_id: organization.id)
  end

  let!(:application) do
    oauth_applications_table.create!(
      name: 'Test App',
      uid: 'test-uid',
      secret: 'secret',
      redirect_uri: 'https://example.com'
    )
  end

  let(:migration) do
    described_class.new(
      start_id: oauth_access_grants_table.minimum(:id),
      end_id: oauth_access_grants_table.maximum(:id),
      batch_table: :oauth_access_grants,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    context 'when there are no revoked grants' do
      before do
        create_grant(revoked_at: nil)
      end

      it 'does not archive any grants' do
        expect { migration.perform }.not_to change { oauth_access_grant_archived_records_table.count }
        expect(oauth_access_grants_table.count).to eq(1)
      end
    end

    context 'with a mix of old and recent revoked grants' do
      let!(:old_revoked_grant_1) { create_grant(revoked_at: 3.months.ago) }
      let!(:old_revoked_grant_2) { create_grant(revoked_at: 2.months.ago) }
      let!(:recently_revoked_grant) { create_grant(revoked_at: 1.week.ago) }
      let!(:active_grant) { create_grant(revoked_at: nil) }

      it 'archives only grants revoked more than 1 month ago' do
        expect { migration.perform }
          .to change { oauth_access_grant_archived_records_table.count }.by(2)
          .and change { oauth_access_grants_table.count }.by(-2)

        remaining_grant_ids = oauth_access_grants_table.pluck(:id)
        expect(remaining_grant_ids).to contain_exactly(recently_revoked_grant.id, active_grant.id)

        archived_grant_ids = oauth_access_grant_archived_records_table.pluck(:id)
        expect(archived_grant_ids).to contain_exactly(old_revoked_grant_1.id, old_revoked_grant_2.id)
      end

      it 'creates archived records with correct attributes' do
        migration.perform

        archived_record = oauth_access_grant_archived_records_table.find_by(id: old_revoked_grant_1.id)

        expect(archived_record).to have_attributes(
          token: old_revoked_grant_1.token,
          organization_id: old_revoked_grant_1.organization_id,
          application_id: old_revoked_grant_1.application_id,
          resource_owner_id: old_revoked_grant_1.resource_owner_id,
          expires_in: old_revoked_grant_1.expires_in,
          redirect_uri: old_revoked_grant_1.redirect_uri,
          scopes: old_revoked_grant_1.scopes,
          code_challenge: old_revoked_grant_1.code_challenge,
          code_challenge_method: old_revoked_grant_1.code_challenge_method,
          id: old_revoked_grant_1.id
        )

        expect(archived_record.revoked_at.to_i).to eq(old_revoked_grant_1.revoked_at.to_i)
        expect(archived_record.created_at.to_i).to eq(old_revoked_grant_1.created_at.to_i)
        expect(archived_record.archived_at).to be_present
      end
    end

    context 'when there are only grants revoked less than 1 month ago' do
      before do
        create_grant(revoked_at: 1.week.ago)
        create_grant(revoked_at: 2.weeks.ago)
      end

      it 'does not archive any grants' do
        expect { migration.perform }.not_to change { oauth_access_grant_archived_records_table.count }
        expect(oauth_access_grants_table.count).to eq(2)
      end
    end

    context 'when there are database errors' do
      let!(:old_grant_to_archive) { create_grant(revoked_at: 3.months.ago) }

      context 'when archive operation fails' do
        it 'does not partially archive grants' do
          # Mock the connection.execute to simulate SQL failure
          allow(ApplicationRecord.connection)
            .to receive(:execute)
                  .and_call_original

          allow(ApplicationRecord.connection)
            .to receive(:execute)
                  .with(a_string_matching(/WITH deleted AS/))
                  .and_raise(ActiveRecord::StatementInvalid, 'Failed to insert')

          expect { migration.perform }.to raise_error(ActiveRecord::StatementInvalid)

          expect(oauth_access_grant_archived_records_table.count).to eq(0)
          expect(oauth_access_grants_table.count).to eq(1)
          expect(oauth_access_grants_table.find(old_grant_to_archive.id)).to be_present
        end
      end
    end
  end

  private

  def create_grant(revoked_at: nil)
    oauth_access_grants_table.create!(
      organization_id: organization.id,
      application_id: application.id,
      resource_owner_id: user.id,
      token: SecureRandom.hex(32),
      revoked_at: revoked_at,
      created_at: revoked_at&.-(1.month) || Time.current,
      expires_in: 3600,
      redirect_uri: 'https://example.com/callback'
    )
  end
end
