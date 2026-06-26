# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillNullOrganizationIdOnOauthApplications,
  feature_category: :system_access do
  let(:organizations) { table(:organizations) }
  let(:oauth_applications) { table(:oauth_applications) }

  let!(:default_org) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:other_org) { organizations.create!(name: 'Other', path: 'other') }

  def create_oauth_application(organization_id:)
    oauth_applications.create!(
      name: "App #{SecureRandom.hex(4)}",
      uid: SecureRandom.hex(16),
      secret: SecureRandom.hex(32),
      redirect_uri: 'https://example.com/callback',
      organization_id: organization_id
    )
  end

  describe '#up' do
    let!(:app_with_null_org) { create_oauth_application(organization_id: nil) }
    let!(:app_with_default_org) { create_oauth_application(organization_id: default_org.id) }
    let!(:app_with_other_org) { create_oauth_application(organization_id: other_org.id) }

    it 'sets organization_id to 1 for rows where it is NULL' do
      migrate!

      expect(app_with_null_org.reload.organization_id).to eq(1)
    end

    it 'does not change rows that already have a non-NULL organization_id' do
      migrate!

      expect(app_with_default_org.reload.organization_id).to eq(default_org.id)
      expect(app_with_other_org.reload.organization_id).to eq(other_org.id)
    end
  end
end
