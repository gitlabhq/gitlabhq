require 'spec_helper'

describe 'GitlabSchema configurations' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }
  let(:query) { graphql_query_for('project', { 'fullPath' => project.full_path }, %w(id name description)) }
  let(:current_user) { create(:user) }

  describe '#max_complexity' do
    context 'when complexity is too high' do
      it 'shows an error' do
        allow(GitlabSchema).to receive(:max_query_complexity).and_return 1

        post_graphql(query, current_user: nil)

        expect(graphql_errors.first['message']).to include('which exceeds max complexity of 1')
      end
    end
  end

  describe '#max_depth' do
    context 'when query depth is too high' do
      it 'shows error' do
        errors = [{ "message" => "Query has depth of 2, which exceeds max depth of 1" }]
        allow(GitlabSchema).to receive(:max_query_depth).and_return 1

        post_graphql(query)

        expect(graphql_errors).to eq(errors)
      end
    end

    context 'when query depth is within range' do
      it 'has no error' do
        allow(GitlabSchema).to receive(:max_query_depth).and_return 5

        post_graphql(query)

        expect(graphql_errors).to be_nil
      end
    end
  end

  context 'when IntrospectionQuery' do
    it 'is not too complex' do
      query = File.read(Rails.root.join('spec/fixtures/api/graphql/introspection.graphql'))

      post_graphql(query, current_user: nil)

      expect(graphql_errors).to be_nil
    end
  end
end
