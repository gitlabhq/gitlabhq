# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Unsubscribing from a work item saved view', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:current_user) { create(:user, developer_of: group) }

  let_it_be(:project_saved_view) do
    create(:saved_view, namespace: project.project_namespace, author: current_user)
  end

  let_it_be(:group_saved_view) do
    create(:saved_view, namespace: group, author: current_user)
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :unsubscribe_work_item_saved_view do
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:mutation) do
      graphql_mutation(
        :workItemSavedViewUnsubscribe,
        { id: project_saved_view.to_global_id.to_s },
        'savedView { id }'
      )
    end

    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :unsubscribe_work_item_saved_view do
    let(:user) { current_user }
    let(:boundary_object) { group }
    let(:mutation) do
      graphql_mutation(
        :workItemSavedViewUnsubscribe,
        { id: group_saved_view.to_global_id.to_s },
        'savedView { id }'
      )
    end

    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
