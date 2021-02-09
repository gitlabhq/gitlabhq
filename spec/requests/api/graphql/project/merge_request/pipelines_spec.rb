# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.mergeRequests.pipelines' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:author) { create(:user) }
  let_it_be(:merge_requests) do
    [
      create(:merge_request, author: author, source_project: project),
      create(:merge_request, :with_image_diffs, author: author, source_project: project),
      create(:merge_request, :conflict, author: author, source_project: project)
    ]
  end

  describe '.count' do
    let(:query) do
      <<~GQL
      query($path: ID!, $first: Int) {
        project(fullPath: $path) {
          mergeRequests(first: $first) {
            nodes {
              iid
              pipelines {
                count
              }
            }
          }
        }
      }
      GQL
    end

    def run_query(first = nil)
      post_graphql(query, current_user: author, variables: { path: project.full_path, first: first })
    end

    before do
      merge_requests.each do |mr|
        shas = mr.all_commits.limit(2).pluck(:sha)

        shas.each do |sha|
          create(:ci_pipeline, :success, project: project, ref: mr.source_branch, sha: sha)
        end
      end
    end

    it 'produces correct results' do
      run_query(2)

      p_nodes = graphql_data_at(:project, :merge_requests, :nodes)

      expect(p_nodes).to all(match('iid' => be_present, 'pipelines' => match('count' => 2)))
    end

    it 'is scalable', :request_store, :use_clean_rails_memory_store_caching do
      # warm up
      run_query

      expect { run_query(2) }.to(issue_same_number_of_queries_as { run_query(1) }.ignoring_cached_queries)
    end
  end
end
