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
# all_records: array of comparison data of all items sorted correctly
# pagination_query: method that specifies the GraphQL query
# pagination_results_data: method that extracts the sorted data used to compare against
#   the expected results
#
# Example:
#   describe 'sorting and pagination' do
#     let_it_be(:sort_project) { create(:project, :public) }
#     let(:data_path)    { [:project, :issues] }
#
#     def pagination_query(arguments)
#       graphql_query_for(:project, { full_path: sort_project.full_path },
#         query_nodes(:issues, :iid, include_pagination_info: true, args: arguments)
#       )
#     end
#
#     # A method transforming nodes to data to match against
#     # default: the identity function
#     def pagination_results_data(issues)
#       issues.map { |issue| issue['iid].to_i }
#     end
#
#     context 'when sorting by weight' do
#       let_it_be(:issues) { make_some_issues_with_weights }
#
#       context 'when ascending' do
#         let(:ordered_issues) { issues.sort_by(&:weight) }
#
#         it_behaves_like 'sorted paginated query' do
#           let(:sort_param) { :WEIGHT_ASC }
#           let(:first_param) { 2 }
#           let(:all_records) { ordered_issues.map(&:iid) }
#         end
#       end
#

# Include this context if your field does not accept a sort argument
RSpec.shared_context 'no sort argument' do
  let(:sort_argument) { graphql_args }
end

RSpec.shared_examples 'sorted paginated query' do |conditions = {}|
  # Provided as a convenience when constructing queries using string concatenation
  let(:page_info) { 'pageInfo { startCursor endCursor }' }
  # Convenience for using default implementation of pagination_results_data
  let(:node_path) { ['id'] }
  let(:sort_argument) { graphql_args(sort: sort_param) }

  it_behaves_like 'requires variables' do
    let(:required_variables) { [:first_param, :all_records, :data_path, :current_user] }
  end

  describe do
    let(:params) { sort_argument }

    # Convenience helper for the large number of queries defined as a projection
    # from some root value indexed by full_path to a collection of objects with IID
    def nested_internal_id_query(root_field, parent, field, args, selection: :iid)
      graphql_query_for(root_field, { full_path: parent.full_path },
        query_nodes(field, selection, args: args, include_pagination_info: true)
      )
    end

    def pagination_query(params)
      raise('pagination_query(params) must be defined in the test, see example in comment') unless defined?(super)

      super
    end

    def pagination_results_data(nodes)
      if defined?(super)
        super(nodes)
      else
        nodes.map { |n| n.dig(*node_path) }
      end
    end

    def results
      nodes = graphql_dig_at(graphql_data(fresh_response_data), *data_path, :nodes)
      pagination_results_data(nodes)
    end

    def end_cursor
      cursor = graphql_dig_at(graphql_data(fresh_response_data), *data_path, :page_info, :end_cursor)
      cursor.is_a?(Array) ? cursor.first : cursor
    end

    def start_cursor
      cursor = graphql_dig_at(graphql_data(fresh_response_data), *data_path, :page_info, :start_cursor)
      cursor.is_a?(Array) ? cursor.first : cursor
    end

    let(:query) { pagination_query(params) }

    before do
      post_graphql(query, current_user: current_user)
    end

    context 'when sorting' do
      it 'sorts correctly' do
        expect(results).to match all_records
      end

      context 'when paginating' do
        let(:params) { sort_argument.merge(first: first_param) }
        let(:first_page) { all_records.first(first_param) }
        let(:rest) { all_records.drop(first_param) }

        it 'paginates correctly' do
          expect(results).to match first_page

          fwds = pagination_query(sort_argument.merge(after: end_cursor))
          post_graphql(fwds, current_user: current_user)

          expect(results).to match rest

          bwds = pagination_query(sort_argument.merge(before: start_cursor))
          post_graphql(bwds, current_user: current_user)

          expect(results).to match first_page
        end
      end

      context 'when last and sort params are present', if: conditions[:is_reversible] do
        let(:params) { sort_argument.merge(last: 1) }

        it 'fetches last elements without error' do
          post_graphql(pagination_query(params), current_user: current_user)

          expect(results.first).to match all_records.last
        end
      end
    end
  end
end
