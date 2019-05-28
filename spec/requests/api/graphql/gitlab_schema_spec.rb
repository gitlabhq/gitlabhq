require 'spec_helper'

describe 'GitlabSchema configurations' do
  include GraphqlHelpers

  let(:project) { create(:project) }

  shared_examples 'imposing query limits' do
    describe '#max_complexity' do
      context 'when complexity is too high' do
        it 'shows an error' do
          allow(GitlabSchema).to receive(:max_query_complexity).and_return 1

          subject

          expect(graphql_errors.flatten.first['message']).to include('which exceeds max complexity of 1')
        end
      end
    end

    describe '#max_depth' do
      context 'when query depth is too high' do
        it 'shows error' do
          errors = { "message" => "Query has depth of 2, which exceeds max depth of 1" }
          allow(GitlabSchema).to receive(:max_query_depth).and_return 1

          subject

          expect(graphql_errors.flatten).to include(errors)
        end
      end

      context 'when query depth is within range' do
        it 'has no error' do
          allow(GitlabSchema).to receive(:max_query_depth).and_return 5

          subject

          expect(Array.wrap(graphql_errors).compact).to be_empty
        end
      end
    end
  end

  context 'regular queries' do
    subject do
      query = graphql_query_for('project', { 'fullPath' => project.full_path }, %w(id name description))
      post_graphql(query)
    end

    it_behaves_like 'imposing query limits'
  end

  context 'multiplexed queries' do
    subject do
      queries = [
        { query: graphql_query_for('project', { 'fullPath' => project.full_path }, %w(id name description)) },
        { query: graphql_query_for('echo', { 'text' => "$test" }, []), variables: { "test" => "Hello world" } }
      ]

      post_multiplex(queries)
    end

    it_behaves_like 'imposing query limits' do
      it "fails all queries when only one of the queries is too complex" do
        # The `project` query above has a complexity of 5
        allow(GitlabSchema).to receive(:max_query_complexity).and_return 4

        subject

        # Expect a response for each query, even though it will be empty
        expect(json_response.size).to eq(2)
        json_response.each do |single_query_response|
          expect(single_query_response).not_to have_key('data')
        end

        # Expect errors for each query
        expect(graphql_errors.size).to eq(2)
        graphql_errors.each do |single_query_errors|
          expect(single_query_errors.first['message']).to include('which exceeds max complexity of 4')
        end
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
