# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a work item saved view', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:current_user) { create(:user, developer_of: group) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :create_work_item_saved_view do
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:mutation) do
      graphql_mutation(
        :workItemSavedViewCreate,
        {
          namespace_path: project.full_path,
          name: 'Project saved view',
          filters: { state: 'opened' },
          display_settings: {},
          sort: 'CREATED_ASC'
        },
        'errors'
      )
    end

    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :create_work_item_saved_view do
    let(:user) { current_user }
    let(:boundary_object) { group }
    let(:mutation) do
      graphql_mutation(
        :workItemSavedViewCreate,
        {
          namespace_path: group.full_path,
          name: 'Group saved view',
          filters: { state: 'opened' },
          display_settings: {},
          sort: 'CREATED_ASC'
        },
        'errors'
      )
    end

    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
