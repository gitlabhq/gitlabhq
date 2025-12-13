# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillScimOauthAccessTokensGroupOrganizationId, migration: :gitlab_main, feature_category: :user_management do
  let(:scim_oauth_access_tokens) { table(:scim_oauth_access_tokens) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'test_org', path: 'test_org') }
  let(:group_namespace) do
    namespaces.create!(
      name: 'test_group',
      path: 'test_group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  before do
    scim_oauth_access_tokens.create!(
      group_id: group_namespace.id,
      organization_id: nil,
      token_encrypted: 'encrypted_token_1'
    )
    scim_oauth_access_tokens.create!(
      group_id: group_namespace.id,
      organization_id: nil,
      token_encrypted: 'encrypted_token_2'
    )

    scim_oauth_access_tokens.create!(
      group_id: group_namespace.id,
      organization_id: organization.id,
      token_encrypted: 'encrypted_token_3'
    )

    scim_oauth_access_tokens.create!(
      group_id: nil,
      organization_id: nil,
      token_encrypted: 'encrypted_token_4'
    )

    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  describe '#up' do
    it 'backfills organization_id for tokens with group_id but no organization_id' do
      expect { migrate! }.to change { scim_oauth_access_tokens.where(organization_id: nil).count }.from(3).to(1)
    end

    it 'sets organization_id based on the group namespace organization' do
      migrate!

      tokens_with_group = scim_oauth_access_tokens.where.not(group_id: nil).order(:id)
      expect(tokens_with_group.pluck(:organization_id)).to eq([organization.id, organization.id, organization.id])
    end

    it 'does not update tokens without group_id' do
      migrate!

      token_without_group = scim_oauth_access_tokens.where(group_id: nil).first
      expect(token_without_group.organization_id).to be_nil
    end

    it 'processes records in batches' do
      expect { migrate! }.to make_queries_matching(/UPDATE\s+"scim_oauth_access_tokens"/, 2)
    end
  end
end
