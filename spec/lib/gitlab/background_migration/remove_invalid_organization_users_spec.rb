# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveInvalidOrganizationUsers, feature_category: :organization do
  let(:organization_users) { table(:organization_users) }

  let!(:organization) { table(:organizations).create!(name: 'MyOrg', path: 'my-org') }
  let!(:user) { table(:users).create!(projects_limit: 10) }
  let!(:valid) { organization_users.create!(user_id: user.id, organization_id: organization.id) }
  let!(:invalid_user) { organization_users.create!(user_id: non_existing_record_id, organization_id: organization.id) }
  let!(:invalid_organization) { organization_users.create!(user_id: user.id, organization_id: non_existing_record_id) }

  let(:migration) do
    described_class.new(
      start_id: valid.id,
      end_id: invalid_organization.id,
      batch_table: :organization_users,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 2.minutes,
      connection: ApplicationRecord.connection
    )
  end

  # Disable FK's: we want to create invalid data
  before(:all) do
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE public.organization_users DROP CONSTRAINT IF EXISTS fk_8471abad75'
    )
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE public.organization_users DROP CONSTRAINT IF EXISTS fk_8d9b20725d'
    )
  end

  after(:all) do
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE public.organization_users
        ADD CONSTRAINT fk_8471abad75 FOREIGN KEY (organization_id)
        REFERENCES organizations(id) ON DELETE RESTRICT NOT VALID'
    )
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE public.organization_users
        ADD CONSTRAINT fk_8d9b20725d FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE NOT VALID'
    )
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    it 'deletes invalid data' do
      perform_migration

      expect(valid).to be_present

      expect(organization_users.exists?(id: invalid_user.id)).to be_falsey
      expect(organization_users.exists?(id: invalid_organization.id)).to be_falsey
    end
  end
end
