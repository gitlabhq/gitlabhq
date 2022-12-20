# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'snippets', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:snippets) { create_list(:personal_snippet, 3, :repository, author: current_user) }

  describe 'querying for all fields' do
    let(:query) do
      graphql_query_for(:snippets, { ids: [global_id_of(snippets.first)] }, <<~SELECT)
        nodes { #{all_graphql_fields_for('Snippet')} }
      SELECT
    end

    it 'can successfully query for snippets and their blobs' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:snippets, :nodes)).to be_one
      expect(graphql_data_at(:snippets, :nodes, :blobs, :nodes)).to be_present
    end
  end
end
