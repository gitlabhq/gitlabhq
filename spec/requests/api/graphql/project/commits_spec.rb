# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project.repository.commit', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }

  let(:query) do
    graphql_query_for(
      'project',
      { fullPath: project.full_path },
      query_graphql_field('repository', {}, query_graphql_field('commit', { ref: 'HEAD' }, 'id sha'))
    )
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_project, :read_code] do
    let(:user) { current_user }
    let(:boundary_object) { project }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end

  describe 'latestPipeline' do
    let_it_be(:commit) { project.commit }

    let_it_be(:default_branch_pipeline) do
      create(:ci_pipeline, project: project, sha: commit.sha, ref: project.default_branch, source: :push)
    end

    # Same SHA on a different ref, created last (higher id) so it wins when unscoped.
    let_it_be(:feature_pipeline) do
      create(:ci_pipeline, project: project, sha: commit.sha, ref: 'feature', source: :push)
    end

    let(:pipeline_ref) { nil }

    let(:query) do
      graphql_query_for(
        'project',
        { fullPath: project.full_path },
        query_graphql_field(
          'repository', {},
          query_graphql_field(
            'commit', { ref: commit.sha },
            query_graphql_field('latestPipeline', { ref: pipeline_ref }, 'id')
          )
        )
      )
    end

    let(:returned_pipeline_id) do
      graphql_data_at(:project, :repository, :commit, :latest_pipeline, :id)
    end

    before do
      post_graphql(query, current_user: current_user)
    end

    context 'when scoped to the default branch' do
      let(:pipeline_ref) { project.default_branch }

      it 'returns the pipeline for that ref' do
        expect(returned_pipeline_id).to eq(default_branch_pipeline.to_global_id.to_s)
      end
    end

    context 'when scoped to another ref' do
      let(:pipeline_ref) { 'feature' }

      it 'returns the pipeline for that ref' do
        expect(returned_pipeline_id).to eq(feature_pipeline.to_global_id.to_s)
      end
    end

    context 'without a ref' do
      it 'returns the latest pipeline across all refs' do
        expect(returned_pipeline_id).to eq(feature_pipeline.to_global_id.to_s)
      end
    end
  end
end
