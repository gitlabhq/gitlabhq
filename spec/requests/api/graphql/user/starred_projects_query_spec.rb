# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting starredProjects of the user' do
  include GraphqlHelpers

  let(:query) do
    graphql_query_for(:user, user_params, user_fields)
  end

  let(:user_params) { { username: user.username } }

  let_it_be(:project_a) { create(:project, :public) }
  let_it_be(:project_b) { create(:project, :private) }
  let_it_be(:project_c) { create(:project, :private) }
  let_it_be(:user, reload: true) { create(:user) }

  let(:user_fields) { 'starredProjects { nodes { id } }' }
  let(:starred_projects) { graphql_data_at(:user, :starred_projects, :nodes) }

  before do
    project_b.add_reporter(user)
    project_c.add_reporter(user)

    user.toggle_star(project_a)
    user.toggle_star(project_b)
    user.toggle_star(project_c)

    post_graphql(query)
  end

  it_behaves_like 'a working graphql query'

  it 'found only public project' do
    expect(starred_projects).to contain_exactly(
      a_hash_including('id' => global_id_of(project_a))
    )
  end

  context 'the current user is the user' do
    let(:current_user) { user }

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'found all projects' do
      expect(starred_projects).to contain_exactly(
        a_hash_including('id' => global_id_of(project_a)),
        a_hash_including('id' => global_id_of(project_b)),
        a_hash_including('id' => global_id_of(project_c))
      )
    end
  end

  context 'the current user is a member of a private project the user starred' do
    let_it_be(:other_user) { create(:user) }

    before do
      project_b.add_reporter(other_user)

      post_graphql(query, current_user: other_user)
    end

    it 'finds public and member projects' do
      expect(starred_projects).to contain_exactly(
        a_hash_including('id' => global_id_of(project_a)),
        a_hash_including('id' => global_id_of(project_b))
      )
    end
  end
end
