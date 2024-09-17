# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project label information', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:parent_group) { create(:group) }
  let_it_be(:project) { create(:project, :public, namespace: parent_group) }
  let_it_be(:label_factory) { :label }
  let_it_be(:label_attrs) { { project: project } }

  it_behaves_like 'querying a GraphQL type with labels' do
    let(:path_prefix) { ['project'] }

    def make_query(fields)
      graphql_query_for('project', { full_path: project.full_path }, fields)
    end
  end

  context 'when searching title within a hierarchy' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:labels_params) { { title: 'priority::1', includeAncestorGroups: true } }
    let_it_be(:project_label) { create(:label, project: project, title: 'priority::1', color: '#FF0000') }
    let_it_be(:parent_group_label) { create(:group_label, group: parent_group, title: 'priority::1', color: '#FF00FF') }

    let(:labels_response) { graphql_data.dig('project', 'labels', 'nodes') }
    let(:query) do
      graphql_query_for('project', { full_path: project.full_path }, [
        query_graphql_field(:labels, labels_params, [query_graphql_field(:nodes, nil, %w[id title])])
      ])
    end

    it 'finds the labels with exact title matching' do
      post_graphql(query, current_user: current_user)
      expect(graphql_errors).not_to be_present

      expect(labels_response.pluck('id')).to contain_exactly(
        project_label.to_global_id.to_s, parent_group_label.to_global_id.to_s
      )
    end
  end
end
