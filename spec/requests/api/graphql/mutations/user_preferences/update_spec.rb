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
      'projectStudioEnabled' => true,
      'newUiEnabled' => true,
      'mergeRequestDashboardShowDrafts' => true
    }
  end

  let(:mutation) { graphql_mutation(:userPreferencesUpdate, input) }
  let(:mutation_response) { graphql_mutation_response(:userPreferencesUpdate) }
  let(:project_studio_available) { true }

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
    allow(Ability).to receive(:allowed?).with(current_user, :enable_project_studio,
      anything).and_return(project_studio_available)
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
      expect(mutation_response['userPreferences']['projectStudioEnabled']).to eq(true)
      expect(mutation_response['userPreferences']['newUiEnabled']).to eq(true)

      expect(current_user.user_preference.persisted?).to eq(true)
      expect(current_user.user_preference.extensions_marketplace_opt_in_status).to eq('enabled')
      expect(current_user.user_preference.extensions_marketplace_opt_in_url).to eq('https://example.com')
      expect(current_user.user_preference.issues_sort).to eq(Types::IssueSortEnum.values[sort_value].value.to_s)
      expect(current_user.user_preference.visibility_pipeline_id_type).to eq('iid')
      expect(current_user.user_preference.use_work_items_view).to eq(true)
      expect(current_user.user_preference.merge_request_dashboard_list_type).to eq('role_based')
      expect(current_user.user_preference.merge_request_dashboard_show_drafts).to eq(true)
      expect(current_user.user_preference.work_items_display_settings).to eq({ 'shouldOpenItemsInSidePanel' => false })
      expect(current_user.user_preference.project_studio_enabled).to eq(true)
      expect(current_user.user_preference.new_ui_enabled).to eq(true)
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
        project_studio_enabled: false,
        new_ui_enabled: false,
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
      expect(mutation_response['userPreferences']['projectStudioEnabled']).to eq(true)
      expect(mutation_response['userPreferences']['newUiEnabled']).to eq(true)

      expect(current_user.user_preference.issues_sort).to eq(Types::IssueSortEnum.values[sort_value].value.to_s)
      expect(current_user.user_preference.visibility_pipeline_id_type).to eq('iid')
      expect(current_user.user_preference.use_work_items_view).to eq(true)
      expect(current_user.user_preference.merge_request_dashboard_list_type).to eq('role_based')
      expect(current_user.user_preference.merge_request_dashboard_show_drafts).to eq(true)
      expect(current_user.user_preference.work_items_display_settings).to eq({
        'shouldOpenItemsInSidePanel' => false
      })
      expect(current_user.user_preference.project_studio_enabled).to eq(true)
      expect(current_user.user_preference.new_ui_enabled).to eq(true)
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
          'useWorkItemsView' => nil,
          'projectStudioEnabled' => nil,
          'newUiEnabled' => nil
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
          work_items_display_settings: init_user_preference[:work_items_display_settings],
          project_studio_enabled: init_user_preference[:project_studio_enabled],
          new_ui_enabled: init_user_preference[:new_ui_enabled]
        })
      end
    end
  end

  describe 'project_studio_enabled specific tests' do
    context 'when setting project_studio_enabled to true' do
      let(:input) do
        {
          'projectStudioEnabled' => true
        }
      end

      before do
        current_user.create_user_preference!(project_studio_enabled: false)
      end

      it 'updates the preference to true' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['userPreferences']['projectStudioEnabled']).to eq(true)
        expect(current_user.user_preference.reload.project_studio_enabled).to eq(true)
      end
    end

    context 'when setting project_studio_enabled to false' do
      let(:input) do
        {
          'projectStudioEnabled' => false
        }
      end

      before do
        current_user.create_user_preference!(project_studio_enabled: true)
      end

      it 'updates the preference to false' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['userPreferences']['projectStudioEnabled']).to eq(false)
        expect(current_user.user_preference.reload.project_studio_enabled).to eq(false)
      end
    end

    context 'when project studio is unavailable' do
      let(:input) do
        {
          'projectStudioEnabled' => true
        }
      end

      let(:project_studio_available) { false }

      before do
        current_user.create_user_preference!(project_studio_enabled: false)
      end

      it 'does not allow enabling project studio' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['userPreferences']['projectStudioEnabled']).to eq(false)
        expect(current_user.user_preference.reload.project_studio_enabled).to eq(false)
      end
    end
  end

  describe 'new_ui_enabled specific tests' do
    context 'when setting new_ui_enabled to true' do
      let(:input) do
        {
          'newUiEnabled' => true
        }
      end

      before do
        current_user.create_user_preference!(new_ui_enabled: false, project_studio_enabled: false)
      end

      it 'updates the preferences to true' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['userPreferences']['newUiEnabled']).to eq(true)
        expect(current_user.user_preference.reload.new_ui_enabled).to eq(true)
        expect(current_user.user_preference.reload.project_studio_enabled).to eq(true)
      end
    end

    context 'when setting new_ui_enabled to false' do
      let(:input) do
        {
          'newUiEnabled' => false
        }
      end

      before do
        current_user.create_user_preference!(new_ui_enabled: true, project_studio_enabled: true)
      end

      it 'updates the preferences to false' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['userPreferences']['newUiEnabled']).to eq(false)
        expect(current_user.user_preference.reload.new_ui_enabled).to eq(false)
        expect(current_user.user_preference.reload.project_studio_enabled).to eq(false)
      end
    end

    context 'when project studio is unavailable' do
      let(:input) do
        {
          'newUiEnabled' => true
        }
      end

      let(:project_studio_available) { false }

      context 'when the setting is pristine' do
        before do
          current_user.create_user_preference!(new_ui_enabled: nil, project_studio_enabled: false)
        end

        it 'does not allow enabling project studio' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['userPreferences']['newUiEnabled']).to eq(nil)
          expect(current_user.user_preference.reload.new_ui_enabled).to eq(nil)
          expect(current_user.user_preference.reload.project_studio_enabled).to eq(false)
        end
      end

      context 'when the setting was already disabled' do
        before do
          current_user.create_user_preference!(new_ui_enabled: false, project_studio_enabled: false)
        end

        it 'does not allow enabling project studio' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['userPreferences']['newUiEnabled']).to eq(false)
          expect(current_user.user_preference.reload.new_ui_enabled).to eq(false)
          expect(current_user.user_preference.reload.project_studio_enabled).to eq(false)
        end
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
end
