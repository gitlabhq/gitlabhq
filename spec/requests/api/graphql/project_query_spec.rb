# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, :repository, group: group) }
  let_it_be(:current_user) { create(:user) }

  let(:project_fields) { all_graphql_fields_for('project'.to_s.classify, max_depth: 1) }

  let(:query) do
    graphql_query_for(:project, { full_path: project.full_path }, project_fields)
  end

  context 'when the user has full access to the project' do
    before do
      project.add_maintainer(current_user)
    end

    it 'includes the project', :use_clean_rails_memory_store_caching, :request_store do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).not_to be_nil
    end
  end

  context 'when the user has access to the project', :use_clean_rails_memory_store_caching, :request_store do
    before_all do
      project.add_developer(current_user)
    end

    it 'includes the project' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).not_to be_nil
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    context 'when there are pipelines present' do
      let(:project_fields) { query_nodes(:pipelines) }

      before do
        create(:ci_pipeline, project: project)
      end

      it 'is included in the pipelines connection' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:project, :pipelines, :nodes)).to contain_exactly(a_kind_of(Hash))
      end
    end

    context 'topics' do
      it 'includes empty topics array if no topics set' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:project, :topics)).to match([])
      end

      it 'includes topics array' do
        project.update!(topic_list: 'topic1, topic2, topic3')

        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:project, :topics)).to match(%w[topic1 topic2 topic3])
      end
    end

    it 'includes inherited members in project_members' do
      group_member = create(:group_member, group: group)
      project_member = create(:project_member, project: project)
      member_query = <<~GQL
        query {
          project(fullPath: "#{project.full_path}") {
            projectMembers {
              nodes {
                id
                user {
                  username
                }
                ... on ProjectMember {
                  project {
                    id
                  }
                }
                ... on GroupMember {
                  group {
                    id
                  }
                }
              }
            }
          }
        }
      GQL

      post_graphql(member_query, current_user: current_user)

      member_ids = graphql_data.dig('project', 'projectMembers', 'nodes')
      expect(member_ids).to include(
        a_hash_including(
          'id' => group_member.to_global_id.to_s,
          'group' => { 'id' => group.to_global_id.to_s }
        )
      )
      expect(member_ids).to include(
        a_hash_including(
          'id' => project_member.to_global_id.to_s,
          'project' => { 'id' => project.to_global_id.to_s }
        )
      )
    end
  end

  context 'when the user has reporter access to the project' do
    let(:statistics_query) do
      <<~GRAPHQL
        {
          project(fullPath: "#{project.full_path}") {
            statistics { wikiSize }
          }
        }
      GRAPHQL
    end

    before do
      project.add_reporter(current_user)
      create(:project_statistics, project: project, wiki_size: 100)
    end

    it 'allows fetching project statistics' do
      post_graphql(statistics_query, current_user: current_user)

      expect(graphql_data.dig('project', 'statistics')).to include('wikiSize' => 100.0)
    end
  end

  context 'when the user does not have access to the project' do
    it 'returns an empty field' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).to be_nil
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end
  end
end
