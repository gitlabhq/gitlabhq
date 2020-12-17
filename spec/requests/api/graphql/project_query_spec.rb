# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:current_user) { create(:user) }
  let(:fields) { all_graphql_fields_for(Project, max_depth: 2, excluded: %w(jiraImports services)) }

  let(:query) do
    graphql_query_for(:project, { full_path: project.full_path }, fields)
  end

  context 'when the user has full access to the project' do
    let(:full_access_query) do
      graphql_query_for(:project, { full_path: project.full_path },
                        all_graphql_fields_for('Project', max_depth: 2))
    end

    before do
      project.add_maintainer(current_user)
    end

    it 'includes the project', :use_clean_rails_memory_store_caching, :request_store do
      post_graphql(full_access_query, current_user: current_user)

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
      before do
        create(:ci_pipeline, project: project)
      end

      let(:fields) { query_nodes(:pipelines) }

      it 'is included in the pipelines connection' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:project, :pipelines, :nodes)).to contain_exactly(a_kind_of(Hash))
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

  describe 'performance' do
    before_all do
      project.add_developer(current_user)
      mrs = create_list(:merge_request, 10, :closed, :with_head_pipeline,
                        source_project: project,
                        author: current_user)
      mrs.each do |mr|
        mr.assignees << create(:user)
        mr.assignees << current_user
      end
    end

    def run_query(number)
      q = <<~GQL
        query {
          project(fullPath: "#{project.full_path}") {
            mergeRequests(first: #{number}) {
              nodes {
                assignees { nodes { username } }
                headPipeline { status }
              }
            }
          }
        }
      GQL

      post_graphql(q, current_user: current_user)
    end

    it 'returns appropriate results' do
      run_query(2)

      mrs = graphql_data.dig('project', 'mergeRequests', 'nodes')

      expect(mrs.size).to eq(2)
      expect(mrs).to all(
        match(
          a_hash_including(
            'assignees' => { 'nodes' => all(match(a_hash_including('username' => be_present))) },
            'headPipeline' => { 'status' => be_present }
          )))
    end

    it 'can lookahead to eliminate N+1 queries' do
      baseline = ActiveRecord::QueryRecorder.new { run_query(1) }
      expect { run_query(10) }.not_to exceed_query_limit(baseline)
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
