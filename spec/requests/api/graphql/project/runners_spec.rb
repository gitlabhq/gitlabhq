# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project.runners', feature_category: :runner do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance) }
  let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
  let_it_be(:other_project) { create(:project, :repository, :public) }
  let_it_be(:other_project_runner) { create(:ci_runner, :project, projects: [other_project]) }

  let_it_be(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          runners {
            nodes {
              id
            }
          }
        }
      }
    )
  end

  context 'when the user is a project admin' do
    before do
      project.add_maintainer(user)
    end

    let(:expected_ids) { [project_runner, group_runner, instance_runner].map { |g| g.to_global_id.to_s } }

    it 'returns all runners available to project' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :runners, :nodes).pluck('id')).to match_array(expected_ids)
    end
  end

  context 'when the user is a project developer' do
    before do
      project.add_developer(user)
    end

    it 'returns no runners' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :runners, :nodes)).to be_empty
    end
  end
end
