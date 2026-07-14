# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project.runners', feature_category: :runner_core do
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

  subject(:request) { post_graphql(query, current_user: user) }

  context 'when the user is a project admin' do
    before do
      project.add_maintainer(user)
    end

    let(:expected_ids) { [project_runner, group_runner, instance_runner].map { |g| g.to_global_id.to_s } }

    it 'returns all runners available to project' do
      request

      expect(graphql_data_at(:project, :runners, :nodes).pluck('id')).to match_array(expected_ids)
    end
  end

  context 'when the user is a project developer' do
    before do
      project.add_developer(user)
    end

    it 'returns nil runners and an error' do
      request

      expect(graphql_data_at(:project, :runners)).to be_nil
      expect(graphql_errors).to contain_exactly(a_hash_including(
        'message' => a_string_including("you don't have permission to perform this action"),
        'path' => %w[project runners]
      ))
    end
  end

  context 'with a runner outside the project' do
    let_it_be(:other_organization) { create(:organization) }
    let_it_be(:other_org_group) { create(:group, organization: other_organization) }
    let_it_be(:other_org_project) { create(:project, group: other_org_group) }
    let_it_be(:other_org_runner) { create(:ci_runner, :project, projects: [other_org_project]) }

    before do
      project.add_maintainer(user)
    end

    it 'does not return runners outside the project', :aggregate_failures do
      request

      returned_ids = graphql_data_at(:project, :runners, :nodes).pluck('id')
      expect(returned_ids).to include(project_runner.to_global_id.to_s)
      expect(returned_ids).not_to include(other_org_runner.to_global_id.to_s)
    end
  end
end
