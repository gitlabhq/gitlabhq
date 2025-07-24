# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Parameterized table necessitates many memoized helpers
RSpec.describe Gitlab::Current::Organization, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:user_organization) { create(:organization) }
  let_it_be(:session_organization) { create(:organization) }
  let_it_be(:header_organization) { create(:organization) }
  let_it_be(:default_organization) { create(:organization, :default) }
  let_it_be(:group) { create(:group, organization: organization) }
  let_it_be(:user) { create(:user, organization_users: [create(:organization_user, organization: user_organization)]) }

  let_it_be(:params_with_namespace_id) { { namespace_id: group.full_path } }
  let_it_be(:params_with_group_id) { { group_id: group.full_path } }
  let_it_be(:params_with_groups_id) { { controller: 'groups', id: group.full_path } }
  let_it_be(:params_with_org_path) { { organization_path: other_organization.path } }
  let_it_be(:params_with_empty_namespace) { { namespace_id: '' } }
  let_it_be(:params_with_invalid_namespace) { { namespace_id: 'not_found' } }
  let_it_be(:params_with_empty_org_path) { { organization_path: '' } }
  let_it_be(:params_with_invalid_org_path) { { organization_path: 'not_found' } }
  let_it_be(:params_with_invalid_groups_id) { { controller: 'groups', id: 'not_found' } }
  let_it_be(:params_with_invalid_group_id) { { group_id: 'not_found' } }
  let_it_be(:empty_params) { {} }
  let_it_be(:session_with_org) { { organization_id: session_organization.id } }
  let_it_be(:session_with_invalid_org) { { organization_id: non_existing_record_id } }
  let_it_be(:empty_session) { {} }
  let_it_be(:nil_session) { nil }
  let_it_be(:headers_with_valid_org) { { 'X-GitLab-Organization-ID' => header_organization.id.to_s } }
  let_it_be(:headers_with_invalid_org) { { 'X-GitLab-Organization-ID' => non_existing_record_id.to_s } }
  let_it_be(:headers_with_zero) { { 'X-GitLab-Organization-ID' => '0' } }
  let_it_be(:headers_with_negative) { { 'X-GitLab-Organization-ID' => '-1' } }
  let_it_be(:headers_with_non_numeric) { { 'X-GitLab-Organization-ID' => 'abc' } }
  let_it_be(:empty_headers) { {} }
  let_it_be(:nil_headers) { nil }

  describe '#organization' do
    subject(:current_organization) do
      described_class.new(params: params, user: user_param, session: session_param, headers: headers_param)
    end

    # rubocop:disable Layout/LineLength -- Parameterized table format requires long lines
    where(:params, :headers_param, :session_param, :user_param, :expected, :enables_fallback) do
      # Valid params take precedence over everything
      ref(:params_with_namespace_id)      | ref(:headers_with_valid_org)   | ref(:session_with_org)         | ref(:user) | ref(:organization)         | false
      ref(:params_with_group_id)          | ref(:headers_with_valid_org)   | ref(:session_with_org)         | ref(:user) | ref(:organization)         | false
      ref(:params_with_groups_id)         | ref(:headers_with_valid_org)   | ref(:session_with_org)         | ref(:user) | ref(:organization)         | false
      ref(:params_with_org_path)          | ref(:headers_with_valid_org)   | ref(:session_with_org)         | ref(:user) | ref(:other_organization)   | false

      # Invalid params fall back to headers, then session, then user, then default
      ref(:params_with_invalid_namespace) | ref(:headers_with_valid_org)   | ref(:session_with_org)         | ref(:user) | ref(:header_organization)  | false
      ref(:params_with_invalid_namespace) | ref(:empty_headers)            | ref(:session_with_org)         | ref(:user) | ref(:session_organization) | false
      ref(:params_with_invalid_namespace) | ref(:headers_with_invalid_org) | ref(:session_with_org)         | ref(:user) | ref(:session_organization) | false
      ref(:params_with_invalid_namespace) | ref(:empty_headers)            | ref(:empty_session)            | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_invalid_namespace) | ref(:headers_with_invalid_org) | ref(:session_with_invalid_org) | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_invalid_namespace) | ref(:empty_headers)            | ref(:empty_session)            | nil        | ref(:default_organization) | true
      ref(:params_with_invalid_namespace) | ref(:headers_with_invalid_org) | ref(:session_with_invalid_org) | nil        | ref(:default_organization) | true

      # Empty params follow same fallback chain
      ref(:empty_params)                  | ref(:headers_with_valid_org)   | ref(:session_with_org)         | ref(:user) | ref(:header_organization)  | false
      ref(:empty_params)                  | ref(:empty_headers)            | ref(:session_with_org)         | ref(:user) | ref(:session_organization) | false
      ref(:empty_params)                  | ref(:headers_with_valid_org)   | ref(:nil_session)              | ref(:user) | ref(:header_organization)  | false
      ref(:empty_params)                  | ref(:headers_with_invalid_org) | ref(:session_with_org)         | ref(:user) | ref(:session_organization) | false
      ref(:empty_params)                  | ref(:empty_headers)            | ref(:empty_session)            | ref(:user) | ref(:user_organization)    | false
      ref(:empty_params)                  | ref(:empty_headers)            | ref(:nil_session)              | ref(:user) | ref(:user_organization)    | false
      ref(:empty_params)                  | ref(:headers_with_invalid_org) | ref(:session_with_invalid_org) | ref(:user) | ref(:user_organization)    | false
      ref(:empty_params)                  | ref(:empty_headers)            | ref(:session_with_invalid_org) | nil        | ref(:default_organization) | true
      ref(:empty_params)                  | ref(:empty_headers)            | ref(:empty_session)            | nil        | ref(:default_organization) | true
      ref(:empty_params)                  | ref(:nil_headers)              | ref(:nil_session)              | nil        | ref(:default_organization) | true

      # Test header regex validation - invalid formats should fall back to user/default
      ref(:empty_params)                  | ref(:headers_with_zero)        | ref(:empty_session)            | ref(:user) | ref(:user_organization)    | false
      ref(:empty_params)                  | ref(:headers_with_negative)    | ref(:empty_session)            | ref(:user) | ref(:user_organization)    | false
      ref(:empty_params)                  | ref(:headers_with_non_numeric) | ref(:empty_session)            | ref(:user) | ref(:user_organization)    | false
      ref(:empty_params)                  | ref(:headers_with_zero)        | ref(:empty_session)            | nil        | ref(:default_organization) | true

      # Test other invalid parameter types to ensure consistent fallback behavior
      ref(:params_with_empty_namespace)   | ref(:empty_headers)            | ref(:empty_session)            | nil        | ref(:default_organization) | true
      ref(:params_with_invalid_groups_id) | ref(:headers_with_valid_org)   | ref(:session_with_org)         | ref(:user) | ref(:header_organization)  | false
      ref(:params_with_invalid_org_path)  | ref(:headers_with_valid_org)   | ref(:session_with_org)         | ref(:user) | ref(:header_organization)  | false
      ref(:params_with_invalid_org_path)  | ref(:headers_with_invalid_org) | ref(:empty_session)            | ref(:user) | ref(:user_organization)    | false
      ref(:params_with_invalid_group_id)  | ref(:headers_with_invalid_org) | ref(:session_with_invalid_org) | nil        | ref(:default_organization) | true
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

    context 'when set_current_organization_from_session is disabled' do
      let(:params) { empty_params }
      let(:headers_param) { empty_headers }
      let(:session_param) { session_with_org }
      let(:user_param) { user }

      before do
        stub_feature_flags(set_current_organization_from_session: false)
      end

      it 'does not load the current organization from session' do
        expect(current_organization.organization).to eq(user_organization)
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
