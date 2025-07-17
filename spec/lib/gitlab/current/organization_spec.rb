# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Current::Organization, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:user_organization) { create(:organization) }
  let_it_be(:default_organization) { create(:organization, :default) }
  let_it_be(:group) { create(:group, organization: organization) }
  let_it_be(:user) { create(:user, organization_users: [create(:organization_user, organization: user_organization)]) }

  let(:params_with_namespace_id) { { namespace_id: group.full_path } }
  let(:params_with_group_id) { { group_id: group.full_path } }
  let(:params_with_groups_id) { { controller: 'groups', id: group.full_path } }
  let(:params_with_org_path) { { organization_path: other_organization.path } }
  let(:params_with_empty_namespace) { { namespace_id: '' } }
  let(:params_with_invalid_namespace) { { namespace_id: 'not_found' } }
  let(:params_with_empty_org_path) { { organization_path: '' } }
  let(:params_with_invalid_org_path) { { organization_path: 'not_found' } }
  let(:params_with_invalid_groups_id) { { controller: 'groups', id: 'not_found' } }
  let(:params_with_invalid_group_id) { { group_id: 'not_found' } }
  let(:empty_params) { {} }

  describe '#organization' do
    subject(:current_organization) { described_class.new(params: params, user: user_param).organization }

    where(:params, :user_param, :expected, :enables_fallback) do
      # Valid params without user - should find organization from params
      ref(:params_with_namespace_id)      | nil        | ref(:organization)         | false
      ref(:params_with_group_id)          | nil        | ref(:organization)         | false
      ref(:params_with_groups_id)         | nil        | ref(:organization)         | false
      ref(:params_with_org_path)          | nil        | ref(:other_organization)   | false

      # Valid params with user - params should take precedence over user
      ref(:params_with_namespace_id)      | ref(:user) | ref(:organization)         | false
      ref(:params_with_group_id)          | ref(:user) | ref(:organization)         | false
      ref(:params_with_groups_id)         | ref(:user) | ref(:organization)         | false
      ref(:params_with_org_path)          | ref(:user) | ref(:other_organization)   | false

      # Params without user when organization is not found - should fall back to default
      ref(:params_with_invalid_namespace) | nil        | ref(:default_organization) | true
      ref(:params_with_empty_namespace)   | nil        | ref(:default_organization) | true
      ref(:params_with_empty_org_path)    | nil        | ref(:default_organization) | true
      ref(:params_with_invalid_org_path)  | nil        | ref(:default_organization) | true
      ref(:params_with_invalid_groups_id) | nil        | ref(:default_organization) | true
      ref(:params_with_invalid_group_id)  | nil        | ref(:default_organization) | true

      # Invalid params with user - should fall back to user (params tried first but failed)
      ref(:params_with_invalid_namespace) | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_empty_namespace)   | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_invalid_org_path)  | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_invalid_groups_id) | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_invalid_group_id)  | ref(:user) | ref(:user_organization)    | false

      # No params with user - should find organization from user
      ref(:empty_params)                 | ref(:user)  | ref(:user_organization)    | false

      # No params without user - should fall back to default
      ref(:empty_params)                 | nil         | ref(:default_organization) | true
    end

    with_them do
      it { is_expected.to eq(expected) }

      it 'sets fallback tracking correctly', :request_store do
        current_organization
        expect(Gitlab::Organizations::FallbackOrganizationTracker.enabled?).to eq(enables_fallback)
      end
    end

    context 'for query optimization' do
      it 'only executes fallback query when namespace_id is empty' do
        expect { described_class.new(params: params_with_empty_namespace).organization }
          .to match_query_count(1) # Only the fallback query
      end

      it 'only executes fallback query when organization_path is empty' do
        expect { described_class.new(params: params_with_empty_org_path).organization }
          .to match_query_count(1)
      end
    end
  end
end
