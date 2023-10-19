# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.mergeRequests.pipelines', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:author) { create(:user) }
  let_it_be(:mr_nodes_path) { [:data, :project, :merge_requests, :nodes] }
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

    before do
      merge_requests.first(2).each do |mr|
        shas = mr.recent_diff_head_shas

        shas.each do |sha|
          create(:ci_pipeline, :success, project: project, ref: mr.source_branch, sha: sha)
        end
      end
    end

    it 'produces correct results' do
      r = run_query(3)

      nodes = graphql_dig_at(r, *mr_nodes_path)

      expect(nodes).to all(match('iid' => be_present, 'pipelines' => include('count' => be_a(Integer))))
      expect(graphql_dig_at(r, *mr_nodes_path, :pipelines, :count)).to contain_exactly(1, 1, 0)
    end

    it 'is scalable', :request_store, :use_clean_rails_memory_store_caching do
      baseline = ActiveRecord::QueryRecorder.new { run_query(1) }

      expect { run_query(2) }.not_to exceed_query_limit(baseline)
    end
  end

  describe '.nodes' do
    let(:query) do
      <<~GQL
      query($path: ID!, $first: Int) {
        project(fullPath: $path) {
          mergeRequests(first: $first) {
            nodes {
              iid
              pipelines {
                count
                nodes { id }
              }
            }
          }
        }
      }
      GQL
    end

    before do
      merge_requests.each do |mr|
        shas = mr.recent_diff_head_shas

        shas.each do |sha|
          create(:ci_pipeline, :success, project: project, ref: mr.source_branch, sha: sha)
        end
      end
    end

    it 'produces correct results' do
      r = run_query

      expect(graphql_dig_at(r, *mr_nodes_path, :pipelines, :nodes, :id).uniq.size).to eq 3
    end

    it 'is scalable', :request_store, :use_clean_rails_memory_store_caching do
      baseline = ActiveRecord::QueryRecorder.new { run_query(1) }

      expect { run_query(2) }.not_to exceed_query_limit(baseline)
    end

    it 'requests merge_request_diffs at most once' do
      r = ActiveRecord::QueryRecorder.new { run_query(2) }

      expect(r.log.grep(/merge_request_diffs/)).to contain_exactly(a_string_including('SELECT'))
    end
  end

  def run_query(first = nil)
    run_with_clean_state(
      query,
      context: { current_user: author },
      variables: { path: project.full_path, first: first }
    )
  end
end
