# frozen_string_literal: true

# Requires `query(params)` , `user`, `issuable_data` and `issuable` bindings
RSpec.shared_examples 'query with a search term' do |fields = [:DESCRIPTION]|
  let(:search_term) { 'bar' }
  let(:ids) { graphql_dig_at(issuable_data, :node, :id) }

  it 'returns only matching issuables' do
    filter_params = { search: search_term, in: fields }
    graphql_query = query(filter_params)

    post_graphql(graphql_query, current_user: user)

    expect(ids).to contain_exactly(issuable.to_global_id.to_s)
  end
end
