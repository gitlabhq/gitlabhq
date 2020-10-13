# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StartupjsHelper do
  describe '#page_startup_graphql_calls' do
    let(:query_location) { 'repository/path_last_commit' }
    let(:query_content) do
      File.read(File.join(Rails.root, 'app/graphql/queries', "#{query_location}.query.graphql"))
    end

    it 'returns an array containing GraphQL Page Startup Calls' do
      helper.add_page_startup_graphql_call(query_location, { ref: 'foo' })

      startup_graphql_calls = helper.page_startup_graphql_calls

      expect(startup_graphql_calls).to include({ query: query_content, variables: { ref: 'foo' } })
    end
  end
end
