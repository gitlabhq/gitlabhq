# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group.sharedProjects', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:group) { create(:group, :public, owners: user, name: "group") }
  let_it_be(:group_2) { create(:group, :public, owners: user) }
  let_it_be(:group_3) { create(:group, :public, owners: user) }
  let_it_be(:project) do
    create(:project, :public, namespace: group_2, developers: user_2, name: "project 1 foo")
  end

  let_it_be(:project_2) do
    create(:project, :internal, :aimed_for_deletion, namespace: group_2, owners: user_2, name: "project 2 bar")
  end

  let_it_be(:project_3) { create(:project, :private, :archived, namespace: group_3, name: "project 3 bar") }

  let(:current_user) { user }
  let(:shared_projects_args) { {} }
  let(:fields) do
    <<~QUERY
    nodes {
      #{all_graphql_fields_for('Project', max_depth: 1, excluded: ['productAnalyticsState'])}
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      query_graphql_field('sharedProjects', shared_projects_args, fields)
    )
  end

  subject(:result) do
    post_graphql(query, current_user: current_user)

    graphql_data_at('group', 'shared_projects', 'nodes')
  end

  before_all do
    create(:project_group_link, project: project, group: group)
    create(:project_group_link, project: project_2, group: group)
    create(:project_group_link, project: project_3, group: group)
  end

  it 'returns shared projects' do
    expect(result).to contain_exactly(
      a_graphql_entity_for(project),
      a_graphql_entity_for(project_2),
      a_graphql_entity_for(project_3)
    )
  end

  describe 'min_access_level' do
    context 'when min_access_level is OWNER' do
      let(:current_user) { user_2 }
      let(:shared_projects_args) { { min_access_level: :OWNER } }

      it 'returns only projects user has owner access to' do
        expect(result).to contain_exactly(
          a_graphql_entity_for(project_2)
        )
      end
    end

    context 'when min_access_level is DEVELOPER' do
      let(:current_user) { user_2 }
      let(:shared_projects_args) { { min_access_level: :DEVELOPER } }

      it 'returns only projects user has developer or higher access to' do
        expect(result).to contain_exactly(
          a_graphql_entity_for(project),
          a_graphql_entity_for(project_2)
        )
      end
    end
  end

  context 'when searching' do
    let(:shared_projects_args) { { search: 'foo' } }

    it 'only returns shared projects that match the search term' do
      expect(result).to contain_exactly(
        a_graphql_entity_for(project)
      )
    end
  end

  context 'when sorting' do
    using RSpec::Parameterized::TableSyntax

    where(:sort, :expected_projects) do
      'name_asc' | [ref(:project), ref(:project_2), ref(:project_3)]
      'name_desc' | [ref(:project_3), ref(:project_2), ref(:project)]
      'path_asc' | [ref(:project), ref(:project_2), ref(:project_3)]
      'path_desc' | [ref(:project_3), ref(:project_2), ref(:project)]
      'id_asc' | [ref(:project), ref(:project_2), ref(:project_3)]
      'id_desc' | [ref(:project_3), ref(:project_2), ref(:project)]
    end

    with_them do
      it "orders correctly" do
        query_with_sort = graphql_query_for(
          'group',
          { 'fullPath' => group.full_path },
          query_graphql_field('sharedProjects', { sort: sort }, fields)
        )
        post_graphql(query_with_sort, current_user: current_user)

        expect(
          graphql_data_at('group', 'shared_projects', 'nodes', 'id')
        ).to eq(expected_projects.map { |project| project.to_global_id.to_s })
      end
    end

    context 'when sorting by similarity' do
      let(:fields) do
        <<~QUERY
        nodes {
          id
        }
        QUERY
      end

      context 'when searching' do
        let(:shared_projects_args) { { search: 'project 3 bar', sort: 'similarity' } }

        it 'sorts by similarity score' do
          post_graphql(query, current_user: current_user)

          expect(graphql_data_at('group', 'shared_projects', 'nodes', 'id')).to eq([
            project_3.to_global_id.to_s,
            project_2.to_global_id.to_s
          ])
        end
      end

      context 'when not searching' do
        let(:shared_projects_args) { { sort: 'similarity' } }

        it 'sorts by id_desc' do
          post_graphql(query, current_user: current_user)

          expect(graphql_data_at('group', 'shared_projects', 'nodes', 'id')).to eq([
            project_3.to_global_id.to_s,
            project_2.to_global_id.to_s,
            project.to_global_id.to_s
          ])
        end
      end
    end
  end

  context 'when providing the programming_language_name argument' do
    let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
    let_it_be(:repository_language) do
      create(:repository_language, project: project, programming_language: ruby, share: 1)
    end

    let(:shared_projects_args) { { programming_language_name: 'ruby' } }

    it 'returns the expected projects' do
      expect(result).to contain_exactly(
        a_graphql_entity_for(project)
      )
    end
  end

  context 'when the user does not have permission to read the project' do
    let_it_be(:user_3) { create(:user) }

    let(:current_user) { user_3 }

    it 'returns only public and internal projects' do
      expect(result).to contain_exactly(
        a_graphql_entity_for(project),
        a_graphql_entity_for(project_2)
      )
    end
  end
end
