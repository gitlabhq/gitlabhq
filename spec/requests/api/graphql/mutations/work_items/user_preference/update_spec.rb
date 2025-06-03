# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'Update work items user preferences', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group, :private) }
  let_it_be(:work_item_type) { WorkItems::Type.default_by_type(:incident) }

  let(:sorting_value) { 'CREATED_ASC' }
  let(:display_settings) { { 'shouldOpenItemsInSidePanel' => true } }

  let(:input) do
    {
      namespacePath: namespace.full_path,
      workItemTypeId: work_item_type&.to_gid,
      sort: sorting_value,
      displaySettings: display_settings
    }
  end

  let(:fields) do
    <<~FIELDS
    errors
    userPreferences {
      namespace {
        path
      }
      workItemType {
        name
      }
      sort
      displaySettings
    }
    FIELDS
  end

  let(:mutation) { graphql_mutation(:WorkItemUserPreferenceUpdate, input, fields) }
  let(:mutation_response) { graphql_mutation_response(:work_item_user_preference_update) }

  shared_examples 'updating work items user preferences' do
    context 'when user does not have access to the namespace' do
      it 'does not update the user preference and return access error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors.first['message']).to eq(
          Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        )
      end
    end

    context 'when user has access to the namespace' do
      before_all do
        namespace.add_guest(user)
      end

      it 'updates the user preferences successfully' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to be_blank
        expect(mutation_response['errors']).to be_blank
        expect(mutation_response['userPreferences']).to eq(
          'namespace' => {
            'path' => namespace.path
          },
          'workItemType' => {
            'name' => work_item_type.name
          },
          'sort' => sorting_value,
          'displaySettings' => display_settings
        )
      end

      context 'when work item type id is not provided' do
        let(:input) do
          {
            namespacePath: namespace.full_path,
            sort: sorting_value,
            displaySettings: display_settings
          }
        end

        it 'updates the user preferences successfully' do
          post_graphql_mutation(mutation, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_blank
          expect(mutation_response['errors']).to be_blank
          expect(mutation_response['userPreferences']).to eq(
            'namespace' => {
              'path' => namespace.path
            },
            'workItemType' => nil,
            'sort' => sorting_value,
            'displaySettings' => display_settings
          )
        end
      end

      context 'when sort value is not available' do
        let_it_be(:sorting_value) { 'DUE_DATE_ASC' }

        it 'updates the user preferences successfully' do
          post_graphql_mutation(mutation, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_blank
          expect(mutation_response['errors']).to include(<<~MESSAGE.squish)
          Sort value "#{sorting_value.downcase}" is not available
          on #{namespace.full_path} for work items type #{work_item_type.name}
          MESSAGE
          expect(mutation_response['userPreferences']).to be_nil
        end
      end

      context 'when display settings are not valid' do
        let_it_be(:display_settings) { { 'shouldOpenItemsInSidePanel' => 'test' } }

        it 'updates the user preferences successfully' do
          post_graphql_mutation(mutation, current_user: user)
          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_blank
          expect(mutation_response['errors']).to include(
            'Display settings must be a valid json schema'
          )
          expect(mutation_response['userPreferences']).to be_nil
        end
      end

      context 'with hiddenMetadataKeys in display settings' do
        let(:display_settings) do
          {
            'shouldOpenItemsInSidePanel' => true,
            'hiddenMetadataKeys' => %w[assignee labels milestone]
          }
        end

        it 'updates the user preferences with hidden metadata keys' do
          post_graphql_mutation(mutation, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_blank
          expect(mutation_response['errors']).to be_blank
          expect(mutation_response['userPreferences']['displaySettings']).to eq(display_settings)
        end
      end
    end
  end

  context 'when namespace is a group' do
    let_it_be(:namespace) { create(:group, :private) }

    it_behaves_like 'updating work items user preferences'
  end

  context 'when namespace is a project' do
    let_it_be(:namespace) { create(:project, :private) }

    it_behaves_like 'updating work items user preferences'
  end
end
