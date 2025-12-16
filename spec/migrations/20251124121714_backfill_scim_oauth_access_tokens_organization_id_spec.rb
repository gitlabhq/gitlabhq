# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillScimOauthAccessTokensOrganizationId, feature_category: :system_access do
  let(:scim_oauth_access_tokens) { table(:scim_oauth_access_tokens) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }

  let!(:default_org) { organizations.create!(id: 1, name: 'Default', path: 'default') }

  describe '#up' do
    context 'when backfilling organization_id for instance-level SCIM tokens' do
      let!(:instance_token) do
        scim_oauth_access_tokens.create!(
          group_id: nil,
          organization_id: nil,
          token_encrypted: '*****************'
        )
      end

      let!(:group) do
        namespaces.create!(
          name: 'test-group',
          path: 'test-group',
          type: 'Group',
          organization_id: default_org.id
        )
      end

      let!(:group_token) do
        scim_oauth_access_tokens.create!(
          group_id: group.id,
          organization_id: nil,
          token_encrypted: '*****************'
        )
      end

      let!(:other_org) { organizations.create!(id: 2, name: 'Other', path: 'other') }

      let!(:existing_org_token) do
        scim_oauth_access_tokens.create!(
          group_id: nil,
          organization_id: other_org.id,
          token_encrypted: '*****************'
        )
      end

      it 'sets organization_id to 1 for instance-level tokens without organization_id' do
        migrate!

        expect(instance_token.reload.organization_id).to eq(1)
      end

      it 'does not modify group-level tokens' do
        migrate!

        expect(group_token.reload.organization_id).to be_nil
      end

      it 'does not modify instance-level tokens that already have organization_id' do
        migrate!

        expect(existing_org_token.reload.organization_id).to eq(2)
      end
    end
  end
end
