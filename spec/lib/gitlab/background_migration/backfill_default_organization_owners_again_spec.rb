# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDefaultOrganizationOwnersAgain, schema: 20231220225325, feature_category: :cell do
  let(:organization_users) { table(:organization_users) }
  let(:users) { table(:users) }

  let!(:first_admin) { users.create!(name: 'first', email: 'first_admin@example.com', projects_limit: 1, admin: true) }
  let!(:last_admin) { users.create!(name: 'last', email: 'last_admin@example.com', projects_limit: 1, admin: true) }
  let!(:user) { users.create!(name: 'user', email: 'user@example.com', projects_limit: 1) }

  subject(:migration) do
    described_class.new(
      start_id: first_admin.id,
      end_id: user.id,
      batch_table: :users,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    context 'with no entries for admin user in organization_users' do
      it 'adds admins correctly with the default organization to organization_users' do
        expect(organization_users.count).to eq(0)

        expect { migration.perform }.to change { organization_users.count }.by(2)

        expect(organization_user_as_owner_exists?(first_admin.id)).to be(true)
        expect(organization_user_as_owner_exists?(last_admin.id)).to be(true)
      end
    end

    context 'when admin already exists in organization_users as a default user' do
      before do
        organization_users.create!(
          organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID,
          user_id: first_admin.id,
          access_level: Gitlab::Access::GUEST
        )
      end

      it 'updates the organization_users entry to owner' do
        expect(organization_users.count).to eq(1)

        expect { migration.perform }.to change { organization_users.count }.by(1)

        expect(organization_user_as_owner_exists?(first_admin.id)).to be(true)
        expect(organization_user_as_owner_exists?(last_admin.id)).to be(true)
      end
    end
  end

  def organization_user_as_owner_exists?(user_id)
    organization_users.exists?(
      organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID,
      user_id: user_id,
      access_level: Gitlab::Access::OWNER
    )
  end
end
