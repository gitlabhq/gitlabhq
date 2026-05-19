# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::UserPreferences::Update, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:sort_value) { 'TITLE_ASC' }

  let(:input) do
    {
      'extensionsMarketplaceOptInStatus' => 'ENABLED',
      'issuesSort' => sort_value,
      'projects_sort' => 'NAME_DESC',
      'organizationGroupsProjectsDisplay' => 'GROUPS',
      'organizationGroupsProjectsSort' => 'NAME_DESC',
      'visibilityPipelineIdType' => 'IID',
      'useWorkItemsView' => true,
      'mergeRequestDashboardListType' => 'ROLE_BASED',
      'workItemsDisplaySettings' => { 'shouldOpenItemsInSidePanel' => false },
      'mergeRequestDashboardShowDrafts' => true
    }
  end

  let(:mutation) { graphql_mutation(:userPreferencesUpdate, input) }
  let(:mutation_response) { graphql_mutation_response(:userPreferencesUpdate) }

  before do
    Gitlab::CurrentSettings.update!(vscode_extension_marketplace: {
      enabled: false,
      preset: 'custom',
      custom_values: {
        item_url: 'https://example.com/item/url',
        service_url: 'https://example.com/service/url',
        resource_url_template: 'https://example.com/resource/url/template'
      }
    })

    allow(Ability).to receive(:allowed?).and_call_original
  end

  context 'when user has no existing preference' do
    it 'creates the user preference record' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['userPreferences']['extensionsMarketplaceOptInStatus']).to eq('ENABLED')
      expect(mutation_response['userPreferences']['issuesSort']).to eq(sort_value)
      expect(mutation_response['userPreferences']['projectsSort']).to eq('NAME_DESC')
      expect(mutation_response['userPreferences']['organizationGroupsProjectsDisplay']).to eq('GROUPS')
      expect(mutation_response['userPreferences']['organizationGroupsProjectsSort']).to eq('NAME_DESC')
      expect(mutation_response['userPreferences']['visibilityPipelineIdType']).to eq('IID')
      expect(mutation_response['userPreferences']['useWorkItemsView']).to eq(true)
      expect(mutation_response['userPreferences']['mergeRequestDashboardListType']).to eq('ROLE_BASED')
      expect(mutation_response['userPreferences']['mergeRequestDashboardShowDrafts']).to eq(true)
      expect(mutation_response['userPreferences']['workItemsDisplaySettings']).to eq({
        'shouldOpenItemsInSidePanel' => false
      })

      expect(current_user.user_preference.persisted?).to eq(true)
      expect(current_user.user_preference.extensions_marketplace_opt_in_status).to eq('enabled')
      expect(current_user.user_preference.extensions_marketplace_opt_in_url).to eq('https://example.com')
      expect(current_user.user_preference.issues_sort).to eq(Types::IssueSortEnum.values[sort_value].value.to_s)
      expect(current_user.user_preference.visibility_pipeline_id_type).to eq('iid')
      expect(current_user.user_preference.use_work_items_view).to eq(true)
      expect(current_user.user_preference.merge_request_dashboard_list_type).to eq('role_based')
      expect(current_user.user_preference.merge_request_dashboard_show_drafts).to eq(true)
      expect(current_user.user_preference.work_items_display_settings).to eq({ 'shouldOpenItemsInSidePanel' => false })
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :update_user_preference do
      let(:user) { current_user }
      let(:boundary_object) { :user }
      let(:authz_mutation) { graphql_mutation(:userPreferencesUpdate, input, 'errors') }
      let(:request) { post_graphql_mutation(authz_mutation, token: { personal_access_token: pat }) }
    end
  end

  context 'when user has existing preference' do
    let(:init_user_preference) do
      {
        extensions_marketplace_opt_in_status: 'enabled',
        issues_sort: Types::IssueSortEnum.values['TITLE_DESC'].value,
        projects_sort: 'CREATED_DESC',
        organization_groups_projects_display: Types::Organizations::GroupsProjectsDisplayEnum.values['GROUPS'].value,
        organization_groups_projects_sort: 'NAME_DESC',
        visibility_pipeline_id_type: 'id',
        use_work_items_view: false,
        merge_request_dashboard_list_type: 'action_based',
        work_items_display_settings: { 'shouldOpenItemsInSidePanel' => true },
        merge_request_dashboard_show_drafts: false
      }
    end

    before do
      current_user.create_user_preference!(init_user_preference)
    end

    it 'updates the existing value' do
      post_graphql_mutation(mutation, current_user: current_user)

      current_user.user_preference.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['userPreferences']['issuesSort']).to eq(sort_value)
      expect(mutation_response['userPreferences']['projectsSort']).to eq('NAME_DESC')
      expect(mutation_response['userPreferences']['organizationGroupsProjectsDisplay']).to eq('GROUPS')
      expect(mutation_response['userPreferences']['organizationGroupsProjectsSort']).to eq('NAME_DESC')
      expect(mutation_response['userPreferences']['visibilityPipelineIdType']).to eq('IID')
      expect(mutation_response['userPreferences']['workItemsDisplaySettings']).to eq({
        'shouldOpenItemsInSidePanel' => false
      })

      expect(current_user.user_preference.issues_sort).to eq(Types::IssueSortEnum.values[sort_value].value.to_s)
      expect(current_user.user_preference.visibility_pipeline_id_type).to eq('iid')
      expect(current_user.user_preference.use_work_items_view).to eq(true)
      expect(current_user.user_preference.merge_request_dashboard_list_type).to eq('role_based')
      expect(current_user.user_preference.merge_request_dashboard_show_drafts).to eq(true)
      expect(current_user.user_preference.work_items_display_settings).to eq({
        'shouldOpenItemsInSidePanel' => false
      })
    end

    context 'when input has nil attributes' do
      let(:input) do
        {
          'extensionsMarketplaceOptInStatus' => nil,
          'issuesSort' => nil,
          'projectsSort' => nil,
          'organizationGroupsProjectsDisplay' => nil,
          'organizationGroupsProjectsSort' => nil,
          'visibilityPipelineIdType' => nil,
          'useWorkItemsView' => nil
        }
      end

      it 'updates only nullable attributes' do
        post_graphql_mutation(mutation, current_user: current_user)

        current_user.user_preference.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to be_nil
        expect(current_user.user_preference).to have_attributes({
          # These are nullable and are expected to change
          issues_sort: nil,
          projects_sort: nil,
          organization_groups_projects_sort: nil,
          # These should not have changed
          organization_groups_projects_display: init_user_preference[:organization_groups_projects_display],
          extensions_marketplace_opt_in_status: init_user_preference[:extensions_marketplace_opt_in_status],
          visibility_pipeline_id_type: init_user_preference[:visibility_pipeline_id_type],
          use_work_items_view: init_user_preference[:use_work_items_view],
          work_items_display_settings: init_user_preference[:work_items_display_settings]
        })
      end
    end
  end

  describe 'work_items_display_settings specific tests' do
    context 'when updating work_items_display_settings' do
      let(:input) do
        {
          'workItemsDisplaySettings' => { 'shouldOpenItemsInSidePanel' => false }
        }
      end

      before do
        current_user.create_user_preference!(
          work_items_display_settings: { 'shouldOpenItemsInSidePanel' => true }
        )
      end

      it 'merges with existing settings' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(current_user.user_preference.reload.work_items_display_settings).to eq({
          'shouldOpenItemsInSidePanel' => false
        })
      end
    end

    context 'when work_items_display_settings has invalid schema' do
      let(:input) do
        {
          'workItemsDisplaySettings' => { 'invalidKey' => 'value' }
        }
      end

      it 'returns validation error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to include('Work items display settings must be a valid json schema')
        expect(mutation_response['userPreferences']).to be_nil
      end
    end

    context 'when work_items_display_settings is empty' do
      let(:input) do
        {
          'workItemsDisplaySettings' => {}
        }
      end

      before do
        current_user.user_preference.update!(work_items_display_settings: { 'shouldOpenItemsInSidePanel' => true })
      end

      it 'allows empty object' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['userPreferences']['workItemsDisplaySettings']).to eq({})
      end
    end
  end

  # orbit_settings uses snake_case JSON keys (following ai_setting_feature_settings precedent).
  # The graphql_mutation helper camelizes nested hash keys, which would corrupt snake_case keys.
  # These tests use post_graphql with a raw query string to accurately reflect how the
  # real frontend sends the payload (no camelization of JSON content).
  describe 'orbit_settings specific tests' do
    let(:orbit_mutation_query) do
      <<~GQL
        mutation($input: UserPreferencesUpdateInput!) {
          userPreferencesUpdate(input: $input) {
            userPreferences { orbitSettings }
            errors
          }
        }
      GQL
    end

    def post_orbit_mutation(orbit_settings_value, user: current_user)
      # Pass variables as a pre-serialized JSON string to prevent the test helper
      # from camelizing snake_case keys inside the JSON payload.
      post_graphql(
        orbit_mutation_query,
        current_user: user,
        variables: { input: { orbitSettings: orbit_settings_value } }.to_json
      )
    end

    context 'when disabling Orbit via orbit_settings' do
      it 'persists orbit_settings with snake_case key and returns it in response' do
        post_orbit_mutation({ 'enabled' => false })

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_data.dig('userPreferencesUpdate', 'userPreferences', 'orbitSettings'))
          .to eq({ 'enabled' => false })
        expect(UserPreference.find_by(user: current_user).orbit_settings)
          .to eq({ 'enabled' => false })
      end
    end

    context 'when merging with existing orbit_settings' do
      before do
        current_user.create_user_preference!(orbit_settings: { 'enabled' => true })
      end

      it 'merges with existing settings' do
        post_orbit_mutation({ 'enabled' => false })

        expect(response).to have_gitlab_http_status(:success)
        expect(UserPreference.find_by(user: current_user).orbit_settings)
          .to eq({ 'enabled' => false })
      end
    end

    context 'when orbit_settings is empty' do
      it 'allows empty object' do
        post_orbit_mutation({})

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_data.dig('userPreferencesUpdate', 'userPreferences', 'orbitSettings'))
          .to eq({})
      end
    end
  end
end
