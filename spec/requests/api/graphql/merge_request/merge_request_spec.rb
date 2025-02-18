# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.merge_request(id)', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:current_user) { create(:user) }

  let(:merge_request_params) { { 'id' => global_id_of(merge_request) } }
  let(:merge_request_data) { graphql_data['mergeRequest'] }
  let(:merge_request_fields) { all_graphql_fields_for('MergeRequest'.classify) }

  let(:query) do
    graphql_query_for('mergeRequest', merge_request_params, merge_request_fields)
  end

  context 'when the user does not have access to the merge request' do
    it_behaves_like 'a working graphql query that returns no data' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end
  end

  context 'when the user does have access' do
    before do
      project.add_reporter(current_user)
    end

    it_behaves_like 'a noteable graphql type we can query' do
      let(:noteable) { merge_request }
      let(:project) { merge_request.project }
      let(:path_to_noteable) { [:merge_request] }

      def query(fields)
        graphql_query_for('mergeRequest', merge_request_params, fields)
      end
    end

    it 'returns the merge request' do
      post_graphql(query, current_user: current_user)

      expect(merge_request_data).to include(
        'title' => merge_request.title,
        'description' => merge_request.description
      )
    end

    context 'when selecting any single field' do
      where(:field) do
        scalar_fields_of('MergeRequest').map { |name| [name] }
      end

      with_them do
        it_behaves_like 'a working graphql query that returns data' do
          let(:merge_request_fields) do
            field
          end

          before do
            post_graphql(query, current_user: current_user)
          end

          it "returns the merge request and field #{params['field']}" do
            expect(merge_request_data.keys).to eq([field])
          end
        end
      end
    end

    context 'when selecting multiple fields' do
      let(:merge_request_fields) { ['title', 'description', 'author { username }'] }

      it 'returns the merge request with the specified fields' do
        post_graphql(query, current_user: current_user)

        expect(merge_request_data.keys).to eq %w[title description author]
        expect(merge_request_data['title']).to eq(merge_request.title)
        expect(merge_request_data['description']).to eq(merge_request.description)
        expect(merge_request_data['author']['username']).to eq(merge_request.author.username)
      end
    end

    context 'when passed a non-merge request gid' do
      let(:issue) { create(:issue) }

      it 'returns an error' do
        gid = issue.to_global_id.to_s
        merge_request_params['id'] = gid

        post_graphql(query, current_user: current_user)

        expect(graphql_errors).not_to be_nil
        expect(graphql_errors.first['message']).to eq("\"#{gid}\" does not represent an instance of MergeRequest")
      end
    end
  end
end
