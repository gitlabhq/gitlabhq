# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting the default merge request target of a project', feature_category: :code_review_workflow do
  include GraphqlHelpers
  include ProjectForksHelper

  let_it_be(:current_user, freeze: false) { create(:user) }
  let_it_be_with_reload(:upstream_project) { create(:project, :public) }

  # fork_project stubs RepositoryForkWorker, so it cannot run inside let_it_be.
  # let! also guarantees the fork exists before contexts restrict the upstream.
  let!(:forked_project) { fork_project(upstream_project, current_user) }

  let(:project) { forked_project }

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      'id defaultMergeRequestTarget { id }'
    )
  end

  let(:result) { graphql_data_at(:project, :default_merge_request_target) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_project] do
    let(:user) { current_user }
    let(:boundary_object) { forked_project }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end

  context 'when the project is not a fork' do
    let(:project) { upstream_project }

    it 'returns the project itself' do
      post_graphql(query, current_user: current_user)

      expect(result).to match(a_graphql_entity_for(upstream_project))
    end
  end

  context 'when the project is a fork that can target the upstream project' do
    it 'returns the upstream project' do
      post_graphql(query, current_user: current_user)

      expect(result).to match(a_graphql_entity_for(upstream_project))
    end
  end

  context 'when the fork targets itself by default' do
    before do
      forked_project.project_setting.update!(mr_default_target_self: true)
    end

    it 'returns the fork itself' do
      post_graphql(query, current_user: current_user)

      expect(result).to match(a_graphql_entity_for(forked_project))
    end
  end

  context 'when the upstream project has merge requests disabled' do
    before do
      upstream_project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
    end

    it 'returns the fork itself' do
      post_graphql(query, current_user: current_user)

      expect(result).to match(a_graphql_entity_for(forked_project))
    end
  end

  context 'when the fork is more restricted than the upstream project' do
    before do
      forked_project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'returns the fork itself' do
      post_graphql(query, current_user: current_user)

      expect(result).to match(a_graphql_entity_for(forked_project))
    end
  end

  context 'when requesting the field for multiple projects' do
    let(:multi_query) do
      graphql_query_for(:projects, {}, 'nodes { id defaultMergeRequestTarget { id } }')
    end

    it 'batches the project setting and fork lookups' do
      fork_project(upstream_project, current_user)
      other_upstream = create(:project, :public)
      fork_project(other_upstream, current_user)
      create(:project, :public)

      query_recorder = ActiveRecord::QueryRecorder.new { post_graphql(multi_query, current_user: current_user) }

      expect_graphql_errors_to_be_empty
      expect(query_recorder.log.count { |query| query.include?('FROM "project_settings"') }).to eq(1)
      expect(query_recorder.log.count { |query| query.include?('FROM "fork_network_members"') }).to eq(1)
    end
  end

  context 'when the current user cannot see the upstream project' do
    before do
      upstream_project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'returns null' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_be_empty
      expect(result).to be_nil
    end
  end
end
