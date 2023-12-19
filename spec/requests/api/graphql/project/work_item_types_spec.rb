# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of work item types for a project', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }

  it_behaves_like 'graphql work item type list request spec' do
    let(:current_user) { developer }
    let(:parent_key) { :project }

    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        query_nodes('WorkItemTypes', work_item_type_fields)
      )
    end
  end
end
