# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.mergeRequest.diffs', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:diff_args) { '' }

  let(:query) do
    <<~GQL
      query($path: ID!, $iid: String!) {
        project(fullPath: $path) {
          mergeRequest(iid: $iid) {
            iid
            diffs#{diff_args} {
              nodes {
                oldPath
                newPath
                aMode
                bMode
                newFile
                renamedFile
                deletedFile
                collapsed
                tooLarge
                diff
              }
              pageInfo {
                hasNextPage
                endCursor
              }
              overflow
            }
          }
        }
      }
    GQL
  end

  let(:diffs_path) { %i[project mergeRequest diffs] }

  def run_query(current_user)
    post_graphql(query, current_user: current_user,
      variables: { path: project.full_path, iid: merge_request.iid.to_s })
  end

  context 'when the current user can read the merge request' do
    it 'returns per-file diffs including the raw patch text', :aggregate_failures do
      run_query(developer)

      nodes = graphql_data_at(*diffs_path, :nodes)

      expect(nodes).to be_present
      expect(nodes).to all(include('newPath' => be_present))
      expect(nodes.map { |node| node['diff'] }.join).to include('@@')
    end
  end

  describe 'pagination' do
    let(:diff_args) { '(first: 1)' }

    it 'returns a single page and advertises the next one', :aggregate_failures do
      run_query(developer)

      cursor = graphql_data_at(*diffs_path, :pageInfo, :endCursor)

      expect(graphql_data_at(*diffs_path, :nodes).size).to eq(1)
      expect(graphql_data_at(*diffs_path, :pageInfo, :hasNextPage)).to be(true)
      expect(cursor).to be_present
      expect(GitlabSchema.cursor_encoder.decode(cursor)).to eq('2')
    end

    it 'returns different files across consecutive pages', :aggregate_failures do
      run_query(developer)
      first_page = graphql_data_at(*diffs_path, :nodes).map { |node| node['newPath'] }
      cursor = graphql_data_at(*diffs_path, :pageInfo, :endCursor)

      second_query = query.sub('(first: 1)', %[(first: 1, after: "#{cursor}")])
      post_graphql(second_query, current_user: developer,
        variables: { path: project.full_path, iid: merge_request.iid.to_s })

      second_page = graphql_data_at(*diffs_path, :nodes).map { |node| node['newPath'] }

      expect(second_page).to be_present
      expect(second_page).not_to match_array(first_page)
    end
  end

  context 'with the expanded argument' do
    let(:diff_args) { '(expanded: true)' }

    it 'accepts the argument and returns per-file diffs', :aggregate_failures do
      run_query(developer)

      nodes = graphql_data_at(*diffs_path, :nodes)

      expect(graphql_errors).to be_nil
      expect(nodes).to be_present
      expect(graphql_data_at(*diffs_path, :overflow)).to be(false)
    end
  end

  context 'when a page overflows the diff size limits' do
    let(:diff_args) { '(expanded: true)' }

    before do
      stub_application_setting(diff_max_lines: 150, diff_max_files: 1000)
    end

    it 'reports overflow on the connection' do
      run_query(developer)

      expect(graphql_data_at(*diffs_path, :overflow)).to be(true)
    end
  end

  context 'when the current user cannot read the merge request' do
    let_it_be(:outsider) { create(:user) }

    it 'does not expose the merge request or its diffs' do
      run_query(outsider)

      expect(graphql_data_at(:project, :mergeRequest)).to be_nil
    end
  end
end
