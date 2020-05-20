# frozen_string_literal: true

# Use this for testing how a GraphQL query handles sorting and pagination.
# This is particularly important when using keyset pagination connection,
# which is the default for ActiveRecord relations, as certain sort keys
# might not be supportable.
#
# sort_param: the value to specify the sort
# data_path: the keys necessary to dig into the return GraphQL data to get the
#   returned results
# first_param: number of items expected (like a page size)
# expected_results: array of comparison data of all items sorted correctly
# pagination_query: method that specifies the GraphQL query
# pagination_results_data: method that extracts the sorted data used to compare against
#   the expected results
#
# Example:
#   describe 'sorting and pagination' do
#     let(:sort_project) { create(:project, :public) }
#     let(:data_path)    { [:project, :issues] }
#
#     def pagination_query(params, page_info)
#       graphql_query_for(
#         'project',
#         { 'fullPath' => sort_project.full_path },
#         "issues(#{params}) { #{page_info} edges { node { iid weight } } }"
#       )
#     end
#
#     def pagination_results_data(data)
#       data.map { |issue| issue.dig('node', 'iid').to_i }
#     end
#
#     context 'when sorting by weight' do
#       ...
#       context 'when ascending' do
#         it_behaves_like 'sorted paginated query' do
#           let(:sort_param)       { 'WEIGHT_ASC' }
#           let(:first_param)      { 2 }
#           let(:expected_results) { [weight_issue3.iid, weight_issue5.iid, weight_issue1.iid, weight_issue4.iid, weight_issue2.iid] }
#         end
#       end
#
RSpec.shared_examples 'sorted paginated query' do
  it_behaves_like 'requires variables' do
    let(:required_variables) { [:sort_param, :first_param, :expected_results, :data_path, :current_user] }
  end

  describe do
    let(:params)       { "sort: #{sort_param}" }
    let(:start_cursor) { graphql_data_at(*data_path, :pageInfo, :startCursor) }
    let(:end_cursor)   { graphql_data_at(*data_path, :pageInfo, :endCursor) }
    let(:sorted_edges) { graphql_data_at(*data_path, :edges) }
    let(:page_info)    { "pageInfo { startCursor endCursor }" }

    def pagination_query(params, page_info)
      raise('pagination_query(params, page_info) must be defined in the test, see example in comment') unless defined?(super)

      super
    end

    def pagination_results_data(data)
      raise('pagination_results_data(data) must be defined in the test, see example in comment') unless defined?(super)

      super(data)
    end

    before do
      post_graphql(pagination_query(params, page_info), current_user: current_user)
    end

    context 'when sorting' do
      it 'sorts correctly' do
        expect(pagination_results_data(sorted_edges)).to eq expected_results
      end

      context 'when paginating' do
        let(:params) { "sort: #{sort_param}, first: #{first_param}" }

        it 'paginates correctly' do
          expect(pagination_results_data(sorted_edges)).to eq expected_results.first(first_param)

          cursored_query = pagination_query("sort: #{sort_param}, after: \"#{end_cursor}\"", page_info)
          post_graphql(cursored_query, current_user: current_user)
          response_data = graphql_dig_at(Gitlab::Json.parse(response.body), :data, *data_path, :edges)

          expect(pagination_results_data(response_data)).to eq expected_results.drop(first_param)
        end
      end
    end
  end
end
