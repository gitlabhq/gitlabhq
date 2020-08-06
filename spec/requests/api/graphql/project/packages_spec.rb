# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a package list for a project' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:package) { create(:package, project: project) }
  let(:packages_data) { graphql_data['project']['packages']['edges'] }

  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('packages'.classify)}
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('packages', {}, fields)
    )
  end

  context 'when user has access to the project' do
    before do
      project.add_reporter(current_user)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns packages successfully' do
      expect(packages_data[0]['node']['name']).to eq package.name
    end
  end

  context 'when the user does not have access to the project/packages' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns nil' do
      expect(graphql_data['project']).to be_nil
    end
  end

  context 'when the user is not autenthicated' do
    before do
      post_graphql(query)
    end

    it_behaves_like 'a working graphql query'

    it 'returns nil' do
      expect(graphql_data['project']).to be_nil
    end
  end
end
