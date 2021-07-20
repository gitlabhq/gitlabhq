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
  let(:current_user) { nil }

  let(:starred_projects) do
    post_graphql(query, current_user: current_user)

    graphql_data_at(:user, :starred_projects, :nodes)
  end

  before do
    project_b.add_reporter(user)
    project_c.add_reporter(user)

    user.toggle_star(project_a)
    user.toggle_star(project_b)
    user.toggle_star(project_c)
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query)
    end
  end

  it 'found only public project' do
    expect(starred_projects).to contain_exactly(
      a_hash_including('id' => global_id_of(project_a))
    )
  end

  context 'the current user is the user' do
    let(:current_user) { user }

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

    let(:current_user) { other_user }

    before do
      project_b.add_reporter(other_user)
    end

    it 'finds public and member projects' do
      expect(starred_projects).to contain_exactly(
        a_hash_including('id' => global_id_of(project_a)),
        a_hash_including('id' => global_id_of(project_b))
      )
    end
  end

  context 'the user has a private profile' do
    before do
      user.update!(private_profile: true)
    end

    context 'the current user does not have access to view the private profile of the user' do
      let(:current_user) { create(:user) }

      it 'finds no projects' do
        expect(starred_projects).to be_empty
      end
    end

    context 'the current user has access to view the private profile of the user' do
      let(:current_user) { create(:admin) }

      it 'finds all projects starred by the user, which the current user has access to' do
        expect(starred_projects).to contain_exactly(
          a_hash_including('id' => global_id_of(project_a)),
          a_hash_including('id' => global_id_of(project_b)),
          a_hash_including('id' => global_id_of(project_c))
        )
      end
    end
  end
end
