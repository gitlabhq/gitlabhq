# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReTrustGroupSamlIdentities, migration: :gitlab_main_user,
  feature_category: :system_access do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:saml_providers) { table(:saml_providers) }
  let(:identities) { table(:identities) }

  let(:organization) { organizations.create!(path: 'org') }

  let(:group) do
    namespaces.create!(name: 'group-with-saml', path: 'group-with-saml', organization_id: organization.id)
  end

  let(:saml_provider) do
    saml_providers.create!(
      group_id: group.id,
      enabled: true,
      certificate_fingerprint: '11:22:33:44:55:66:77:88:99:00:aa:bb:cc:dd:ee:ff:00:11:22:33',
      sso_url: 'https://saml.example.com/sso'
    )
  end

  let!(:untrusted_group_saml_identity) do
    identities.create!(
      provider: 'group_saml',
      extern_uid: 'untrusted-uid',
      user_id: create_user('untrusted').id,
      saml_provider_id: saml_provider.id,
      trusted_extern_uid: false
    )
  end

  let!(:null_trust_group_saml_identity) do
    identities.create!(
      provider: 'group_saml',
      extern_uid: 'null-trust-uid',
      user_id: create_user('null-trust').id,
      saml_provider_id: saml_provider.id,
      trusted_extern_uid: nil
    )
  end

  let!(:trusted_group_saml_identity) do
    identities.create!(
      provider: 'group_saml',
      extern_uid: 'trusted-uid',
      user_id: create_user('trusted').id,
      saml_provider_id: saml_provider.id,
      trusted_extern_uid: true
    )
  end

  let!(:untrusted_other_provider_identity) do
    identities.create!(
      provider: 'bitbucket',
      extern_uid: 'bitbucket-uid',
      user_id: create_user('bitbucket').id,
      trusted_extern_uid: false
    )
  end

  def create_user(username)
    users.create!(
      email: "#{username}@example.com",
      username: username,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  describe '#up' do
    it 'restores trust only for untrusted group SAML identities', :aggregate_failures do
      migrate!

      expect(untrusted_group_saml_identity.reload.trusted_extern_uid).to be(true)
      expect(trusted_group_saml_identity.reload.trusted_extern_uid).to be(true)
      expect(null_trust_group_saml_identity.reload.trusted_extern_uid).to be_nil
    end

    it 'leaves identities of other providers untouched' do
      migrate!

      expect(untrusted_other_provider_identity.reload.trusted_extern_uid).to be(false)
    end
  end
end
