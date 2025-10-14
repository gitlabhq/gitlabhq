# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ArchiveRevokedAccessTokens, feature_category: :system_access do
  let(:oauth_access_tokens_table) { table(:oauth_access_tokens) }
  let(:oauth_access_token_archived_records_table) { table(:oauth_access_token_archived_records) }
  let(:oauth_applications_table) { table(:oauth_applications) }
  let(:organizations_table) { table(:organizations) }

  let!(:organization) { organizations_table.create!(name: 'Test Organization', path: 'test') }
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
      start_id: oauth_access_tokens_table.minimum(:id),
      end_id: oauth_access_tokens_table.maximum(:id),
      batch_table: :oauth_access_tokens,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    context 'when there are no revoked tokens' do
      before do
        create_token(revoked_at: nil)
      end

      it 'does not archive any tokens' do
        expect { migration.perform }.not_to change { oauth_access_token_archived_records_table.count }
        expect(oauth_access_tokens_table.count).to eq(1)
      end
    end

    context 'when there is a mix of old and recent revoked tokens', :freeze_time do
      let!(:old_revoked_token_1) { create_token(revoked_at: 3.months.ago) }
      let!(:old_revoked_token_2) { create_token(revoked_at: 2.months.ago) }
      let!(:recently_revoked_token) { create_token(revoked_at: 1.week.ago) }
      let!(:active_token) { create_token(revoked_at: nil) }

      it 'archives only tokens revoked more than 1 month ago' do
        expect { migration.perform }
          .to change { oauth_access_token_archived_records_table.count }.by(2)
          .and change { oauth_access_tokens_table.count }.by(-2)

        remaining_token_ids = oauth_access_tokens_table.pluck(:id)
        expect(remaining_token_ids).to contain_exactly(recently_revoked_token.id, active_token.id)

        archived_token_ids = oauth_access_token_archived_records_table.pluck(:id)
        expect(archived_token_ids).to contain_exactly(old_revoked_token_1.id, old_revoked_token_2.id)
      end

      it 'creates archived records with correct attributes' do
        migration.perform

        archived_record = oauth_access_token_archived_records_table.find_by(id: old_revoked_token_1.id)

        expect(archived_record).to have_attributes(
          id: old_revoked_token_1.id,
          resource_owner_id: old_revoked_token_1.resource_owner_id,
          organization_id: old_revoked_token_1.organization_id,
          application_id: old_revoked_token_1.application_id,
          token: old_revoked_token_1.token,
          refresh_token: old_revoked_token_1.refresh_token,
          scopes: old_revoked_token_1.scopes,
          expires_in: old_revoked_token_1.expires_in
        )

        expect(archived_record.revoked_at.to_i).to eq(old_revoked_token_1.revoked_at.to_i)
        expect(archived_record.created_at.to_i).to eq(old_revoked_token_1.created_at.to_i)
        expect(archived_record.archived_at.to_i).to be_present
      end
    end

    context 'when there are only tokens revoked less than 1 month ago' do
      before do
        create_token(revoked_at: 1.week.ago)
        create_token(revoked_at: 2.weeks.ago)
      end

      it 'does not archive any tokens' do
        expect { migration.perform }.not_to change { oauth_access_token_archived_records_table.count }
        expect(oauth_access_tokens_table.count).to eq(2)
      end
    end

    context 'when there are database errors' do
      let!(:old_token_to_archive) { create_token(revoked_at: 3.months.ago) }

      context 'when archive operation fails' do
        it 'does not partially archive tokens' do
          # Mock the connection.execute to simulate SQL failure
          allow(ApplicationRecord.connection)
            .to receive(:execute)
                  .and_call_original

          allow(ApplicationRecord.connection)
            .to receive(:execute)
                  .with(a_string_matching(/WITH deleted AS/))
                  .and_raise(ActiveRecord::StatementInvalid, 'Failed to insert')

          expect { migration.perform }.to raise_error(ActiveRecord::StatementInvalid)

          expect(oauth_access_token_archived_records_table.count).to eq(0)
          expect(oauth_access_tokens_table.count).to eq(1)
          expect(oauth_access_tokens_table.find(old_token_to_archive.id)).to be_present
        end
      end
    end
  end

  private

  def create_token(revoked_at: nil, **attrs)
    oauth_access_tokens_table.create!(
      organization_id: organization.id,
      application_id: application.id,
      token: SecureRandom.hex(32),
      revoked_at: revoked_at,
      created_at: revoked_at&.-(1.month) || Time.current,
      **attrs
    )
  end
end
