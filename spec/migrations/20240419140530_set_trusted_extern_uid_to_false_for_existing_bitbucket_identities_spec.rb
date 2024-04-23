# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetTrustedExternUidToFalseForExistingBitbucketIdentities, feature_category: :system_access do
  let!(:google_oauth2_identity) do
    table(:identities).create!(id: 1, provider: 'google_oauth2')
  end

  let!(:github_identity) do
    table(:identities).create!(id: 2, provider: 'github')
  end

  let!(:salesforce_identity) do
    table(:identities).create!(id: 3, provider: 'salesforce')
  end

  let!(:bitbucket_identity1) do
    table(:identities).create!(id: 4, provider: 'bitbucket')
  end

  let!(:group_saml_identity) do
    table(:identities).create!(id: 5, provider: 'group_saml')
  end

  let!(:bitbucket_identity2) do
    table(:identities).create!(id: 6, provider: 'bitbucket')
  end

  let!(:bitbucket_identity3) do
    table(:identities).create!(id: 7, provider: 'bitbucket')
  end

  describe '#up' do
    it 'sets trusted_extern_uid to false for existing bitbucket identities', :aggregate_failures do
      expect(google_oauth2_identity.reload.trusted_extern_uid).to eq(true)
      expect(github_identity.reload.trusted_extern_uid).to eq(true)
      expect(salesforce_identity.reload.trusted_extern_uid).to eq(true)
      expect(bitbucket_identity1.reload.trusted_extern_uid).to eq(true)
      expect(group_saml_identity.reload.trusted_extern_uid).to eq(true)
      expect(bitbucket_identity2.reload.trusted_extern_uid).to eq(true)
      expect(bitbucket_identity3.reload.trusted_extern_uid).to eq(true)

      migrate!

      expect(google_oauth2_identity.reload.trusted_extern_uid).to eq(true)
      expect(github_identity.reload.trusted_extern_uid).to eq(true)
      expect(salesforce_identity.reload.trusted_extern_uid).to eq(true)
      expect(bitbucket_identity1.reload.trusted_extern_uid).to eq(false)
      expect(group_saml_identity.reload.trusted_extern_uid).to eq(true)
      expect(bitbucket_identity2.reload.trusted_extern_uid).to eq(false)
      expect(bitbucket_identity3.reload.trusted_extern_uid).to eq(false)
    end
  end
end
