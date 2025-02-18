# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project, reload: true) { create(:project, :repository, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

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

      expect(graphql_data['project']).to include('id' => global_id_of(project).to_s)
    end

    context 'when querying for pipeline triggers' do
      let(:project_fields) { query_nodes(:pipeline_triggers) }
      let(:pipeline_trigger) { project.triggers.first }

      before do
        create(:ci_trigger, project: project, owner: current_user)
      end

      it 'fetches the pipeline trigger tokens' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:project, :pipeline_triggers, :nodes).first).to match({
          'id' => pipeline_trigger.to_global_id.to_s,
          'canAccessProject' => true,
          'description' => pipeline_trigger.description,
          'expiresAt' => nil,
          'hasTokenExposed' => true,
          'lastUsed' => nil,
          'token' => pipeline_trigger.token
        })
      end

      it 'does not produce N+1 queries' do
        baseline = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

        build_list(:ci_trigger, 2, owner: current_user, project: project)

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(baseline)
      end

      context 'when another project member or owner who is not also the token owner' do
        before do
          project.add_owner(other_user)
          post_graphql(query, current_user: other_user)
        end

        it 'is not authorized and shows truncated token' do
          expect(graphql_data_at(:project, :pipeline_triggers, :nodes).first).to match({
            'id' => pipeline_trigger.to_global_id.to_s,
            'canAccessProject' => true,
            'description' => pipeline_trigger.description,
            'expiresAt' => nil,
            'hasTokenExposed' => false,
            'lastUsed' => nil,
            'token' => pipeline_trigger.short_token
          })
        end
      end

      context 'when user is not a member of a public project' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          post_graphql(query, current_user: other_user)
        end

        it 'cannot read the token' do
          expect(graphql_data_at(:project, :pipeline_triggers, :nodes)).to eql([])
        end
      end
    end
  end

  context 'when the user has access to the project', :use_clean_rails_memory_store_caching, :request_store do
    before_all do
      project.add_developer(current_user)
    end

    it 'includes the project' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).to include('id' => global_id_of(project).to_s)
    end

    it_behaves_like 'a working graphql query that returns data' do
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

  describe 'is_catalog_resource' do
    before do
      project.add_owner(current_user)
    end

    let(:catalog_resource_query) do
      <<~GRAPHQL
        {
          project(fullPath: "#{project.full_path}") {
            isCatalogResource
          }
        }
      GRAPHQL
    end

    context 'when the project is not a catalog resource' do
      it 'is false' do
        post_graphql(catalog_resource_query, current_user: current_user)

        expect(graphql_data.dig('project', 'isCatalogResource')).to be(false)
      end
    end

    context 'when the project is a catalog resource' do
      before do
        create(:ci_catalog_resource, project: project)
      end

      it 'is true' do
        post_graphql(catalog_resource_query, current_user: current_user)

        expect(graphql_data.dig('project', 'isCatalogResource')).to be(true)
      end
    end

    context 'for N+1 queries with isCatalogResource' do
      let_it_be(:project1) { create(:project, group: group) }
      let_it_be(:project2) { create(:project, group: group) }

      it 'avoids N+1 database queries' do
        pending('See: https://gitlab.com/gitlab-org/gitlab/-/issues/403634')
        ctx = { current_user: current_user }

        baseline_query = graphql_query_for(:project, { full_path: project1.full_path }, 'isCatalogResource')

        query = <<~GQL
          query {
            a: #{query_graphql_field(:project, { full_path: project1.full_path }, 'isCatalogResource')}
            b: #{query_graphql_field(:project, { full_path: project2.full_path }, 'isCatalogResource')}
          }
        GQL

        control = ActiveRecord::QueryRecorder.new do
          run_with_clean_state(baseline_query, context: ctx)
        end

        expect { run_with_clean_state(query, context: ctx) }.not_to exceed_query_limit(control)
      end
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

  context 'when the user has guest access' do
    context 'when the project has public pipelines' do
      before do
        pipeline = create(:ci_pipeline, project: project)
        create(:ci_build, project: project, pipeline: pipeline, name: 'a test job')
        project.add_guest(current_user)
      end

      it 'shows all jobs' do
        query = <<~GQL
          query {
            project(fullPath: "#{project.full_path}") {
              jobs {
                nodes {
                  name
                  stage {
                    name
                  }
                }
              }
            }
          }
        GQL

        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:project, :jobs, :nodes)).to contain_exactly({
          'name' => 'a test job',
          'stage' => { 'name' => 'test' }
        })
      end
    end
  end

  context 'when the user does not have access to the project' do
    it_behaves_like 'a working graphql query that returns no data' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end
  end

  context 'with timelog categories' do
    let_it_be(:timelog_category) do
      create(:timelog_category, namespace: project.project_namespace, name: 'TimelogCategoryTest')
    end

    let(:project_fields) do
      <<~GQL
        timelogCategories {
          nodes {
            #{all_graphql_fields_for('TimeTrackingTimelogCategory')}
          }
        }
      GQL
    end

    context 'when user is guest and the project is public' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      end

      it 'includes empty timelog categories array' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:project, :timelogCategories, :nodes)).to match([])
      end
    end

    context 'when user has reporter role' do
      before do
        project.add_reporter(current_user)
      end

      it 'returns the timelog category with all its fields' do
        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:project, :timelogCategories, :nodes))
          .to contain_exactly(a_graphql_entity_for(timelog_category))
      end

      context 'when timelog_categories flag is disabled' do
        before do
          stub_feature_flags(timelog_categories: false)
        end

        it 'returns no timelog categories' do
          post_graphql(query, current_user: current_user)

          expect(graphql_data_at(:project, :timelogCategories)).to be_nil
        end
      end
    end

    context 'for N+1 queries' do
      let!(:project1) { create(:project) }
      let!(:project2) { create(:project) }

      before do
        project1.add_reporter(current_user)
        project2.add_reporter(current_user)
      end

      it 'avoids N+1 database queries' do
        pending('See: https://gitlab.com/gitlab-org/gitlab/-/issues/369396')

        ctx = { current_user: current_user }

        baseline_query = <<~GQL
          query {
            a: project(fullPath: "#{project1.full_path}") { ... p }
          }

          fragment p on Project {
            timelogCategories { nodes { name } }
          }
        GQL

        query = <<~GQL
          query {
            a: project(fullPath: "#{project1.full_path}") { ... p }
            b: project(fullPath: "#{project2.full_path}") { ... p }
          }

          fragment p on Project {
            timelogCategories { nodes { name } }
          }
        GQL

        control = ActiveRecord::QueryRecorder.new do
          run_with_clean_state(baseline_query, context: ctx)
        end

        expect { run_with_clean_state(query, context: ctx) }.not_to exceed_query_limit(control)
      end
    end
  end

  describe 'maxAccessLevel' do
    let(:project_fields) { 'maxAccessLevel { integerValue }' }

    it 'returns access level of the current user in the project' do
      project.add_developer(current_user)

      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:project, :maxAccessLevel, :integerValue)).to eq(Gitlab::Access::DEVELOPER)
    end

    shared_examples 'public project in which the user has no membership' do
      it 'returns no access' do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

        post_graphql(query, current_user: current_user)

        expect(graphql_data_at(:project, :maxAccessLevel, :integerValue)).to eq(Gitlab::Access::NO_ACCESS)
      end
    end

    it_behaves_like 'public project in which the user has no membership'

    context 'when the user is not authenticated' do
      let(:current_user) { nil }

      it_behaves_like 'public project in which the user has no membership'
    end
  end
end
