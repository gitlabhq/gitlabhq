# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveRowsWithDeletedUserFromIdentities, feature_category: :system_access do
  let(:connection) { ApplicationRecord.connection }

  let(:identities) { table(:identities) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:user) { users.create!(email: generate(:email), projects_limit: 0, organization_id: organization.id) }
  let(:user_to_delete) { users.create!(email: generate(:email), projects_limit: 0, organization_id: organization.id) }

  let(:migration) do
    described_class.new(
      start_id: identities.minimum(:id),
      end_id: identities.maximum(:id),
      batch_table: :identities,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 100,
      connection: connection
    )
  end

  describe '#perform' do
    it 'removes the orphan rows and leaves the others intact' do
      identity = identities.create!(user_id: user.id, provider: 'foo')
      orphan_identity = identities.create!(user_id: user_to_delete.id, provider: 'bar')

      drop_constraint
      user_to_delete.destroy!
      recreate_constraint
      expect(users.where(id: user_to_delete.id).count).to eq(0)
      expect(identities.where(id: identity.id).count).to eq(1)
      expect(identities.where(id: orphan_identity.id).count).to eq(1)

      expect { migration.perform }.to change { identities.count }.by(-1)

      expect(identities.where(id: identity.id).count).to eq(1)
      expect(identities.where(id: orphan_identity.id).count).to eq(0)
    end
  end

  private

  def drop_constraint
    connection.execute(
      <<~SQL
        ALTER TABLE identities DROP CONSTRAINT IF EXISTS fk_5373344100;
      SQL
    )
  end

  def recreate_constraint
    connection.execute(
      <<~SQL
      ALTER TABLE ONLY identities
        ADD CONSTRAINT fk_5373344100 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT VALID;
      SQL
    )
  end
end
