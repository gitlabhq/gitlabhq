# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'querying namespace settings', feature_category: :api do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  let(:omniauth_provider_config_oidc) do
    GitlabSettings::Options.new(
      name: 'openid_connect',
      label: 'OpenID Connect',
      step_up_auth: {
        namespace: {
          id_token: {
            required: {
              acr: 'gold'
            }
          }
        }
      }
    )
  end

  let(:fields) do
    <<~QUERY
      namespaceSettings {
        stepUpAuthRequiredOauthProvider
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      fields
    )
  end

  before do
    stub_omniauth_setting(enabled: true, providers: [omniauth_provider_config_oidc])
    allow(Devise).to receive(:omniauth_providers).and_return(['openid_connect'])
  end

  context 'when user has admin permission' do
    before_all do
      group.add_owner(user)
    end

    it 'returns general settings with step-up auth provider' do
      # Ensure the user has owner permissions (in case previous tests changed it)
      group.add_owner(user)
      group.update!(step_up_auth_required_oauth_provider: 'openid_connect')

      post_graphql(query, current_user: user)

      expect(graphql_data_at(:group, :namespaceSettings, :stepUpAuthRequiredOauthProvider))
        .to eq('openid_connect')
    end

    it 'returns nil when not configured' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:group, :namespaceSettings, :stepUpAuthRequiredOauthProvider))
        .to be_nil
    end

    it 'works for subgroups' do
      # Ensure the user has owner permissions for both group and subgroup
      group.add_owner(user)
      subgroup.add_owner(user)
      subgroup.update!(step_up_auth_required_oauth_provider: 'openid_connect')

      subgroup_query = graphql_query_for(
        'group',
        { 'fullPath' => subgroup.full_path },
        fields
      )

      post_graphql(subgroup_query, current_user: user)

      expect(graphql_data_at(:group, :namespaceSettings, :stepUpAuthRequiredOauthProvider))
        .to eq('openid_connect')
    end
  end

  context 'when user lacks admin permission' do
    before_all do
      group.add_developer(user)
    end

    it 'returns nil for generalSettings' do
      # Don't try to update the group - this test is about authorization, not the setting itself
      # Just test that the GraphQL field returns nil when user doesn't have permission
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:group, :namespaceSettings)).to be_nil
    end
  end

  context 'when feature flag is disabled' do
    let(:test_group) { create(:group) }
    let(:test_user) { create(:user) }

    let(:test_query) do
      graphql_query_for(
        'group',
        { 'fullPath' => test_group.full_path },
        fields
      )
    end

    before do
      test_group.add_owner(test_user)
      stub_feature_flags(omniauth_step_up_auth_for_namespace: false)
      # Set the provider directly to namespace_settings to bypass validation when feature flag is off
      test_group.namespace_settings.update_column(:step_up_auth_required_oauth_provider, 'openid_connect')
    end

    it 'returns nil for stepUpAuthRequiredOauthProvider' do
      post_graphql(test_query, current_user: test_user)

      expect(graphql_data_at(:group, :namespaceSettings, :stepUpAuthRequiredOauthProvider))
        .to be_nil
    end
  end
end
