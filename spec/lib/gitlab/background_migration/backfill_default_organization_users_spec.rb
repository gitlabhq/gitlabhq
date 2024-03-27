# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDefaultOrganizationUsers,
  schema: 20240213210124,
  feature_category: :cell do
  let(:organization_users) { table(:organization_users) }
  let(:users) { table(:users) }

  let!(:first_user) { users.create!(name: 'first', email: 'first_user@example.com', projects_limit: 1) }
  let!(:last_user) { users.create!(name: 'last', email: 'last_user@example.com', projects_limit: 1) }
  let!(:admin) { users.create!(name: 'admin user', email: 'admin_user@example.com', projects_limit: 1, admin: true) }

  subject(:migration) do
    described_class.new(
      start_id: first_user.id,
      end_id: admin.id,
      batch_table: :users,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    context 'with no entries for a regular user in organization_users' do
      it 'adds regular users correctly with the default organization to organization_users' do
        expect(organization_users.count).to eq(0)

        expect { migration.perform }.to change { organization_users.count }.by(2)

        expect(organization_user_as_regular_user_exists?(first_user.id)).to be(true)
        expect(organization_user_as_regular_user_exists?(last_user.id)).to be(true)
      end
    end

    context 'when user already exists in organization_users as an admin user' do
      before do
        organization_users.create!(
          organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID,
          user_id: first_user.id,
          access_level: Gitlab::Access::OWNER
        )
      end

      it 'updates the organization_users entry to a regular user' do
        expect(organization_users.count).to eq(1)

        expect { migration.perform }.to change { organization_users.count }.by(1)

        expect(organization_user_as_regular_user_exists?(first_user.id)).to be(true)
        expect(organization_user_as_regular_user_exists?(last_user.id)).to be(true)
      end
    end
  end

  def organization_user_as_regular_user_exists?(user_id)
    organization_users.exists?(
      organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID,
      user_id: user_id,
      access_level: Gitlab::Access::GUEST
    )
  end
end
