# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveScimTokenAndScimIdentityNonRootGroup, feature_category: :system_access do
  let(:namespaces) { table(:namespaces) }
  let(:scim_oauth_access_tokens) { table(:scim_oauth_access_tokens) }
  let(:scim_identities) { table(:scim_identities) }
  let(:users) { table(:users) }
  let(:root_group) do
    namespaces.create!(name: 'root_group', path: 'foo', parent_id: nil, type: 'Group')
  end

  let(:non_root_group) do
    namespaces.create!(name: 'non_root_group', path: 'non_root', parent_id: root_group.id, type: 'Group')
  end

  let(:root_group_user) do
    users.create!(name: 'Example User', email: 'user@example.com', projects_limit: 0)
  end

  let(:non_root_group_user) do
    users.create!(username: 'user2', email: 'user2@example.com', projects_limit: 10)
  end

  it 'removes scim_oauth_access_tokens that belong to non-root group and related scim_identities' do
    scim_oauth_access_token_root_group = scim_oauth_access_tokens.create!(
      group_id: root_group.id,
      token_encrypted: Gitlab::CryptoHelper.aes256_gcm_encrypt(SecureRandom.hex(50))
    )
    scim_oauth_access_token_non_root_group = scim_oauth_access_tokens.create!(
      group_id: non_root_group.id,
      token_encrypted: Gitlab::CryptoHelper.aes256_gcm_encrypt(SecureRandom.hex(50))
    )

    scim_identity_root_group = scim_identities.create!(
      group_id: root_group.id,
      extern_uid: "12345",
      user_id: root_group_user.id,
      active: true
    )

    scim_identity_non_root_group = scim_identities.create!(
      group_id: non_root_group.id,
      extern_uid: "12345",
      user_id: non_root_group_user.id,
      active: true
    )

    expect { migrate! }.to change { scim_oauth_access_tokens.count }.from(2).to(1)
    expect(scim_oauth_access_tokens.find_by_id(scim_oauth_access_token_non_root_group.id)).to be_nil
    expect(scim_identities.find_by_id(scim_identity_non_root_group.id)).to be_nil

    expect(scim_oauth_access_tokens.find_by_id(scim_oauth_access_token_root_group.id)).not_to be_nil
    expect(scim_identities.find_by_id(scim_identity_root_group.id)).not_to be_nil
  end
end
