# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StartupjsHelper do
  using RSpec::Parameterized::TableSyntax

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

  describe '#page_startup_graphql_headers' do
    where(:csrf_token, :feature_category, :expected) do
      'abc'       | 'web_ide' | { 'X-CSRF-Token' => 'abc', 'x-gitlab-feature-category' => 'web_ide' }
      ''          | ''        | { 'X-CSRF-Token' => '', 'x-gitlab-feature-category' => '' }
      'abc'       | nil       | { 'X-CSRF-Token' => 'abc', 'x-gitlab-feature-category' => '' }
      'something' | '   '     | { 'X-CSRF-Token' => 'something', 'x-gitlab-feature-category' => '' }
    end

    with_them do
      before do
        allow(helper).to receive(:form_authenticity_token).and_return(csrf_token)
        ::Gitlab::ApplicationContext.push(feature_category: feature_category)
      end

      it 'returns hash of headers for GraphQL requests' do
        expect(helper.page_startup_graphql_headers).to eq(expected)
      end
    end
  end
end
