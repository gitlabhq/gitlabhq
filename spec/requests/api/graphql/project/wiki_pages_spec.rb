# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a project wiki pages list', feature_category: :wiki do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project, freeze: false) { create(:project, :private, developers: current_user) }
  let_it_be(:wiki, freeze: false) { project.wiki }

  let_it_be(:wiki_pages, freeze: false) do
    %w[apple banana].map { |title| create(:wiki_page, wiki: wiki, title: title) }
  end

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:wiki_pages, 'title', args: { first: 1 }, include_pagination_info: true)
    )
  end

  # Guards that the `wiki_pages` field on ProjectType is wired with the forward-only
  # externally-paginated connection extension. Without it, `first` never reaches the resolver,
  # so it fetches all pages and reports `hasNextPage: false`, failing this example.
  it 'paginates through the connection extension' do
    post_graphql(query, current_user: current_user)

    expect(graphql_errors).to be_nil
    expect(graphql_data_at(:project, :wiki_pages, :nodes).size).to eq(1)
    expect(graphql_data_at(:project, :wiki_pages, :page_info, :has_next_page)).to be(true)
  end

  it 'returns nil for a user who cannot read the wiki' do
    post_graphql(query, current_user: create(:user))

    expect(graphql_data_at(:project, :wiki_pages)).to be_nil
  end
end
