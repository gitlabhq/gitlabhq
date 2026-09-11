# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reordering a work item saved view', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:current_user) { create(:user, developer_of: group) }

  let_it_be(:project_saved_view) do
    create(:saved_view, namespace: project.project_namespace, author: current_user)
  end

  let_it_be(:project_saved_view_2) do
    create(:saved_view, namespace: project.project_namespace, author: current_user)
  end

  let_it_be(:group_saved_view) do
    create(:saved_view, namespace: group, author: current_user)
  end

  let_it_be(:group_saved_view_2) do
    create(:saved_view, namespace: group, author: current_user)
  end

  let_it_be(:project_user_saved_view) do
    create(:user_saved_view, user: current_user, saved_view: project_saved_view,
      namespace: project.project_namespace, relative_position: 100)
  end

  let_it_be(:project_user_saved_view_2) do
    create(:user_saved_view, user: current_user, saved_view: project_saved_view_2,
      namespace: project.project_namespace, relative_position: 200)
  end

  let_it_be(:group_user_saved_view) do
    create(:user_saved_view, user: current_user, saved_view: group_saved_view,
      namespace: group, relative_position: 100)
  end

  let_it_be(:group_user_saved_view_2) do
    create(:user_saved_view, user: current_user, saved_view: group_saved_view_2,
      namespace: group, relative_position: 200)
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :reorder_work_item_saved_view do
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:mutation) do
      graphql_mutation(
        :workItemSavedViewReorder,
        {
          id: project_saved_view.to_global_id.to_s,
          move_after_id: project_saved_view_2.to_global_id.to_s
        },
        'errors'
      )
    end

    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :reorder_work_item_saved_view do
    let(:user) { current_user }
    let(:boundary_object) { group }
    let(:mutation) do
      graphql_mutation(
        :workItemSavedViewReorder,
        {
          id: group_saved_view.to_global_id.to_s,
          move_after_id: group_saved_view_2.to_global_id.to_s
        },
        'errors'
      )
    end

    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
