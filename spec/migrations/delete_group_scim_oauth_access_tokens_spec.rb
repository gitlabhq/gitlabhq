# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteGroupScimOauthAccessTokens, feature_category: :system_access do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:scim_oauth_access_tokens) { table(:scim_oauth_access_tokens) }

  let(:organization) { organizations.create!(name: 'Default', path: 'default') }

  let(:group) do
    namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let!(:group_token) do
    scim_oauth_access_tokens.create!(
      group_id: group.id,
      organization_id: organization.id,
      token_encrypted: 'group-token'
    )
  end

  let!(:instance_token) do
    scim_oauth_access_tokens.create!(
      group_id: nil,
      organization_id: organization.id,
      token_encrypted: 'instance-token'
    )
  end

  it 'deletes group-level tokens and keeps instance-level tokens' do
    expect { migrate! }.to change { scim_oauth_access_tokens.count }.from(2).to(1)

    expect(scim_oauth_access_tokens.pluck(:id)).to contain_exactly(instance_token.id)
  end
end
