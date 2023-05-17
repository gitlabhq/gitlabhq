# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveSamlProviderAndIdentitiesNonRootGroup, feature_category: :system_access do
  let(:namespaces) { table(:namespaces) }
  let(:saml_providers) { table(:saml_providers) }
  let(:identities) { table(:identities) }
  let(:root_group) do
    namespaces.create!(name: 'root_group', path: 'foo', parent_id: nil, type: 'Group')
  end

  let(:non_root_group) do
    namespaces.create!(name: 'non_root_group', path: 'non_root', parent_id: root_group.id, type: 'Group')
  end

  it 'removes saml_providers that belong to non-root group and related identities' do
    provider_root_group = saml_providers.create!(
      group_id: root_group.id,
      sso_url: 'https://saml.example.com/adfs/ls',
      certificate_fingerprint: '55:44:33:22:11:aa:bb:cc:dd:ee:ff:11:22:33:44:55:66:77:88:99',
      default_membership_role: ::Gitlab::Access::GUEST,
      enabled: true
    )

    identity_root_group = identities.create!(
      saml_provider_id: provider_root_group.id,
      extern_uid: "12345"
    )

    provider_non_root_group = saml_providers.create!(
      group_id: non_root_group.id,
      sso_url: 'https://saml.example.com/adfs/ls',
      certificate_fingerprint: '55:44:33:22:11:aa:bb:cc:dd:ee:ff:11:22:33:44:55:66:77:88:99',
      default_membership_role: ::Gitlab::Access::GUEST,
      enabled: true
    )

    identity_non_root_group = identities.create!(
      saml_provider_id: provider_non_root_group.id,
      extern_uid: "12345"
    )

    expect { migrate! }.to change { saml_providers.count }.from(2).to(1)

    expect(identities.find_by_id(identity_non_root_group.id)).to be_nil
    expect(saml_providers.find_by_id(provider_non_root_group.id)).to be_nil

    expect(identities.find_by_id(identity_root_group.id)).not_to be_nil
    expect(saml_providers.find_by_id(provider_root_group.id)).not_to be_nil
  end
end
