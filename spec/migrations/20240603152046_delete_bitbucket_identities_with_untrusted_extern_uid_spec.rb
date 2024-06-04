# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteBitbucketIdentitiesWithUntrustedExternUid, feature_category: :system_access do
  let!(:google_oauth2_identity) do
    table(:identities).create!(id: 1, provider: 'google_oauth2')
  end

  let!(:github_identity_with_untrusted_extern_uid) do
    table(:identities).create!(id: 2, provider: 'github', trusted_extern_uid: false)
  end

  let!(:salesforce_identity_with_untrusted_extern_uid) do
    table(:identities).create!(id: 3, provider: 'salesforce', trusted_extern_uid: false)
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

  let!(:bitbucket_identity_with_untrusted_extern_uid1) do
    table(:identities).create!(id: 7, provider: 'bitbucket', trusted_extern_uid: false)
  end

  let!(:bitbucket_identity3) do
    table(:identities).create!(id: 8, provider: 'bitbucket')
  end

  let!(:bitbucket_identity_with_untrusted_extern_uid2) do
    table(:identities).create!(id: 9, provider: 'bitbucket', trusted_extern_uid: false)
  end

  let!(:bitbucket_identity_with_untrusted_extern_uid3) do
    table(:identities).create!(id: 10, provider: 'bitbucket', trusted_extern_uid: false)
  end

  describe '#up' do
    it 'deletes Bitbucket identities with untrusted extern_uid', :aggregate_failures do
      migrate!

      expect(table(:identities).exists?(google_oauth2_identity.id)).to eq(true)
      expect(table(:identities).exists?(github_identity_with_untrusted_extern_uid.id)).to eq(true)
      expect(table(:identities).exists?(salesforce_identity_with_untrusted_extern_uid.id)).to eq(true)
      expect(table(:identities).exists?(bitbucket_identity1.id)).to eq(true)
      expect(table(:identities).exists?(group_saml_identity.id)).to eq(true)
      expect(table(:identities).exists?(bitbucket_identity2.id)).to eq(true)
      expect(table(:identities).exists?(bitbucket_identity_with_untrusted_extern_uid1.id)).to eq(false)
      expect(table(:identities).exists?(bitbucket_identity3.id)).to eq(true)
      expect(table(:identities).exists?(bitbucket_identity_with_untrusted_extern_uid2.id)).to eq(false)
      expect(table(:identities).exists?(bitbucket_identity_with_untrusted_extern_uid3.id)).to eq(false)
    end
  end
end
