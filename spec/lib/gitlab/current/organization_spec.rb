# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Current::Organization, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:user_organization) { create(:organization) }
  let_it_be(:session_organization) { create(:organization) }
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
  let(:session_with_org) { { organization_id: session_organization.id } }
  let(:session_with_invalid_org) { { organization_id: non_existing_record_id } }
  let(:empty_session) { {} }
  let(:nil_session) { nil }

  describe '#organization' do
    subject(:current_organization) do
      described_class.new(params: params, user: user_param, session: session_param)
    end

    # rubocop:disable Layout/LineLength -- Parameterized table format requires long lines
    where(:params, :session_param, :user_param, :expected, :enables_fallback) do
      # Valid params
      ref(:params_with_namespace_id)      | ref(:session_with_org)         | ref(:user) | ref(:organization)         | false
      ref(:params_with_group_id)          | ref(:session_with_org)         | ref(:user) | ref(:organization)         | false
      ref(:params_with_groups_id)         | ref(:session_with_org)         | ref(:user) | ref(:organization)         | false
      ref(:params_with_org_path)          | ref(:session_with_org)         | ref(:user) | ref(:other_organization)   | false

      # Invalid params fall back to session, then user, then default
      ref(:params_with_invalid_namespace) | ref(:session_with_org)         | ref(:user) | ref(:session_organization) | false
      ref(:params_with_invalid_namespace) | ref(:empty_session)            | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_invalid_namespace) | ref(:session_with_invalid_org) | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_invalid_namespace) | ref(:empty_session)            | nil        | ref(:default_organization) | true
      ref(:params_with_invalid_namespace) | ref(:session_with_invalid_org) | nil        | ref(:default_organization) | true

      # Empty params follow same fallback chain
      ref(:empty_params)                  | ref(:session_with_org)         | ref(:user) | ref(:session_organization) | false
      ref(:empty_params)                  | ref(:empty_session)            | ref(:user) | ref(:user_organization)    | false
      ref(:empty_params)                  | ref(:nil_session)              | ref(:user) | ref(:user_organization)    | false
      ref(:empty_params)                  | ref(:session_with_invalid_org) | ref(:user) | ref(:user_organization)    | false
      ref(:empty_params)                  | ref(:session_with_invalid_org) | nil        | ref(:default_organization) | true
      ref(:empty_params)                  | ref(:empty_session)            | nil        | ref(:default_organization) | true
      ref(:empty_params)                  | ref(:nil_session)              | nil        | ref(:default_organization) | true

      # Test other invalid parameter types to ensure consistent fallback behavior
      ref(:params_with_empty_namespace)   | ref(:empty_session)            | nil        | ref(:default_organization) | true
      ref(:params_with_invalid_groups_id) | ref(:session_with_org)         | ref(:user) | ref(:session_organization) | false
      ref(:params_with_invalid_org_path)  | ref(:empty_session)            | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_invalid_group_id)  | ref(:session_with_invalid_org) | nil        | ref(:default_organization) | true
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it 'correctly sets the current organization' do
        expect(current_organization.organization).to eq(expected)
      end

      it 'sets fallback tracking correctly', :request_store do
        current_organization.organization

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
