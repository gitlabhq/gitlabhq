require 'spec_helper'

describe 'GitlabSchema configurations' do
  include GraphqlHelpers

  it 'shows an error if complexity is too high' do
    project = create(:project, :repository)
    query   = graphql_query_for('project', { 'fullPath' => project.full_path }, %w(id name description))

    allow(GitlabSchema).to receive(:max_query_complexity).and_return 1

    post_graphql(query, current_user: nil)

    expect(graphql_errors.first['message']).to include('which exceeds max complexity of 1')
  end

  context 'when IntrospectionQuery' do
    it 'is not too complex' do
      query = File.read(Rails.root.join('spec/fixtures/api/graphql/introspection.graphql'))

      post_graphql(query, current_user: nil)

      expect(graphql_errors).to be_nil
    end
  end
end
