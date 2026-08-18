# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillNullOrganizationIdOnKeys,
  migration: :gitlab_main_org,
  feature_category: :system_access do
  let(:organizations) { table(:organizations) }
  let(:keys) { table(:keys) }

  let!(:default_org) { organizations.create!(id: described_class::ORG_ID, name: 'Default', path: 'default') }
  let!(:other_org) { organizations.create!(name: 'Other', path: 'other') }

  # The NOT NULL check constraint (check_8933ae4f38) is removed automatically by
  # the migration harness: testing this migration rolls the schema down to just
  # before it, which runs 20260714092408's #down (remove_not_null_constraint).
  # That lets us insert rows with a NULL organization_id here, reproducing the
  # state on Self-Managed/Dedicated instances that have not yet been backfilled.
  def create_key(organization_id:)
    keys.create!(organization_id: organization_id)
  end

  describe '#up' do
    let!(:key_with_null_org) { create_key(organization_id: nil) }
    let!(:key_with_default_org) { create_key(organization_id: default_org.id) }
    let!(:key_with_other_org) { create_key(organization_id: other_org.id) }

    it 'sets organization_id to the default org for rows where it is NULL' do
      migrate!

      expect(key_with_null_org.reload.organization_id).to eq(described_class::ORG_ID)
    end

    it 'does not change rows that already have a non-NULL organization_id' do
      migrate!

      expect(key_with_default_org.reload.organization_id).to eq(default_org.id)
      expect(key_with_other_org.reload.organization_id).to eq(other_org.id)
    end
  end
end
