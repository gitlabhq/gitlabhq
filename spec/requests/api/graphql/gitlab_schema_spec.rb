# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GitlabSchema configurations', feature_category: :integrations do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }

  shared_examples 'imposing query limits' do
    describe 'timeouts' do
      context 'when timeout is reached' do
        it 'shows an error' do
          allow_any_instance_of(Gitlab::Graphql::Timeout).to receive(:max_seconds).and_return(0)

          subject

          expect_graphql_errors_to_include(/Timeout/)
        end
      end
    end

    describe '#max_complexity' do
      context 'when complexity is too high' do
        it 'shows an error' do
          allow(GitlabSchema).to receive(:max_query_complexity).and_return 1

          subject

          expect_graphql_errors_to_include(/which exceeds max complexity of 1/)
        end
      end
    end

    describe '#max_depth' do
      context 'when query depth is too high' do
        it 'shows error' do
          allow(GitlabSchema).to receive(:max_query_depth).and_return 1

          subject

          expect_graphql_errors_to_include(/exceeds max depth/)
        end
      end

      context 'when query depth is within range' do
        it 'has no error' do
          allow(GitlabSchema).to receive(:max_query_depth).and_return 5

          subject

          expect_graphql_errors_to_be_empty
        end
      end
    end
  end

  context 'depth, complexity and recursion checking' do
    context 'unauthenticated recursive queries' do
      context 'a not-quite-recursive-enough introspective query' do
        it 'succeeds' do
          query = File.read(Rails.root.join('spec/fixtures/api/graphql/small-recursive-introspection.graphql'))

          post_graphql(query, current_user: nil)

          expect_graphql_errors_to_be_empty
        end
      end

      context 'failing queries' do
        before do
          allow(GitlabSchema).to receive(:max_query_recursion).and_return 1
        end

        context 'a recursive introspective query' do
          it 'fails due to recursion' do
            query = File.read(Rails.root.join('spec/fixtures/api/graphql/recursive-introspection.graphql'))

            post_graphql(query, current_user: nil)

            expect_graphql_errors_to_include [/Recursive query/]
          end
        end

        context 'a recursive non-introspective query' do
          before do
            allow(GitlabSchema).to receive(:max_query_complexity).and_return 1
            allow(GitlabSchema).to receive(:max_query_depth).and_return 1
            allow(GitlabSchema).to receive(:max_query_complexity).and_return 1
          end

          shared_examples 'fails due to recursion, complexity and depth' do |fixture_file|
            it 'fails due to recursion, complexity and depth' do
              query = File.read(Rails.root.join(fixture_file))

              post_graphql(query, current_user: nil)

              expect_graphql_errors_to_include [/Recursive query/, /exceeds max complexity/, /exceeds max depth/]
            end
          end

          context 'using `nodes` notation' do
            it_behaves_like 'fails due to recursion, complexity and depth', 'spec/fixtures/api/graphql/recursive-query-nodes.graphql'
          end

          context 'using `edges -> node` notation' do
            it_behaves_like 'fails due to recursion, complexity and depth', 'spec/fixtures/api/graphql/recursive-query-edges-node.graphql'
          end
        end
      end
    end
  end

  context 'regular queries' do
    subject do
      query = graphql_query_for('project', { 'fullPath' => project.full_path }, %w[id name description])
      post_graphql(query)
    end

    it_behaves_like 'imposing query limits'
  end

  context 'multiplexed queries' do
    let(:current_user) { nil }

    subject do
      queries = [
        { query: graphql_query_for('project', { 'fullPath' => '$fullPath' }, %w[id name description]) }, # Complexity 4
        { query: graphql_query_for('echo', { 'text' => "$test" }, []), variables: { "test" => "Hello world" } }, # Complexity 1
        { query: graphql_query_for('project', { 'fullPath' => project.full_path }, "userPermissions { createIssue }") } # Complexity 3
      ]

      post_multiplex(queries, current_user: current_user)
    end

    it 'does not authenticate all queries' do
      subject

      expect(json_response.last['data']['project']).to be_nil
    end

    shared_examples 'query is too complex' do |description, max_complexity|
      it description, :aggregate_failures do
        allow(GitlabSchema).to receive(:max_query_complexity).and_return max_complexity

        subject

        # Expect a response for each query, even though it will be empty
        expect(json_response.size).to eq(3)
        json_response.each do |single_query_response|
          expect(single_query_response).not_to have_key('data')
        end

        # Expect errors for each query
        expect(graphql_errors.size).to eq(3)
        graphql_errors.each do |single_query_errors|
          expect_graphql_errors_to_include(/Query has complexity of 8, which exceeds max complexity of #{max_complexity}/)
        end
      end
    end

    it_behaves_like 'imposing query limits' do
      # The total complexity of the multiplex query above is 8
      it_behaves_like 'query is too complex', 'fails all queries when only one of the queries is too complex', 4
      it_behaves_like 'query is too complex', 'fails when all queries combined are too complex', 7
    end

    context 'authentication' do
      let(:current_user) { project.first_owner }

      it 'authenticates all queries' do
        subject

        expect(json_response.last['data']['project']['userPermissions']['createIssue']).to be(true)
      end
    end
  end

  context 'when IntrospectionQuery' do
    it 'is not too complex nor recursive' do
      query = CachedIntrospectionQuery.query_string

      post_graphql(query, current_user: nil)

      expect_graphql_errors_to_be_empty
    end
  end

  context 'logging' do
    let(:query) { CachedIntrospectionQuery.query_string }

    it 'logs the query complexity and depth' do
      expect_any_instance_of(Gitlab::Graphql::QueryAnalyzers::AST::LoggerAnalyzer).to receive(:duration).and_return(7)

      expect(Gitlab::GraphqlLogger).to receive(:info).with(
        hash_including(
          trace_type: 'execute_query',
          "query_analysis.duration_s" => 7,
          "query_analysis.complexity" => an_instance_of(Integer),
          "query_analysis.depth" => an_instance_of(Integer),
          "query_analysis.used_deprecated_fields" => an_instance_of(Array),
          "query_analysis.used_deprecated_arguments" => an_instance_of(Array),
          "query_analysis.used_fields" => an_instance_of(Array)
        )
      )

      post_graphql(query, current_user: nil)
    end

    it 'logs using `format_message`' do
      expect_any_instance_of(Gitlab::GraphqlLogger).to receive(:format_message)

      post_graphql(query, current_user: nil)
    end
  end

  context "global id's" do
    it 'uses GlobalID to expose ids' do
      post_graphql(
        graphql_query_for('project', { 'fullPath' => project.full_path }, %w[id]),
        current_user: project.first_owner
      )

      parsed_id = GlobalID.parse(graphql_data['project']['id'])

      expect(parsed_id).to eq(project.to_global_id)
    end
  end

  describe 'removal of deprecated items' do
    let(:mock_schema) do
      Class.new(GraphQL::Schema) do
        lazy_resolve ::Gitlab::Graphql::Lazy, :force

        query(Class.new(::Types::BaseObject) do
          graphql_name 'Query'

          field :foo, GraphQL::Types::Boolean, deprecated: { milestone: '0.1', reason: :renamed }

          field :bar, (Class.new(::Types::BaseEnum) do
            graphql_name 'BarEnum'

            value 'FOOBAR', value: 'foobar', deprecated: { milestone: '0.1', reason: :renamed }
            value 'FOOBARNEW', value: 'foobarnew'
          end)

          field :baz, GraphQL::Types::Boolean do
            argument :arg, String, required: false, deprecated: { milestone: '0.1', reason: :renamed }
          end

          def foo
            false
          end

          def bar
            'foobar'
          end

          def baz(arg:)
            false
          end
        end)
      end
    end

    let(:params) { {} }
    let(:headers) { {} }

    before do
      allow(GitlabSchema).to receive(:execute).and_wrap_original do |method, *args, **kwargs|
        mock_schema.execute(*args, **kwargs)
      end
    end

    context 'without `remove_deprecated` param' do
      it 'shows deprecated items' do
        query = '{ foo bar baz(arg: "test") }'

        post_graphql(query, params: params, headers: headers)

        expect(json_response).to include('data' => { 'foo' => false, 'bar' => 'FOOBAR', 'baz' => false })
      end
    end

    context 'with `remove_deprecated` param' do
      let(:params) { { remove_deprecated: '1' } }

      it 'hides deprecated field' do
        query = '{ foo }'

        post_graphql(query, params: params)

        expect(json_response).not_to include('data' => { 'foo' => false })
        expect(json_response).to include(
          'errors' => include(a_hash_including('message' => /Field 'foo' doesn't exist on type 'Query'/))
        )
      end

      it 'hides deprecated enum value' do
        query = '{ bar }'

        post_graphql(query, params: params)

        expect(json_response).not_to include('data' => { 'bar' => 'FOOBAR' })
        expect(json_response).to include(
          'errors' => include(
            a_hash_including(
              'message' => /`Query.bar` returned `"foobar"` at `bar`, but this isn't a valid value for `BarEnum`/
            )
          )
        )
      end

      it 'hides deprecated argument' do
        query = '{ baz(arg: "test") }'

        post_graphql(query, params: params)

        expect(json_response).not_to include('data' => { 'bar' => 'FOOBAR' })
        expect(json_response).to include(
          'errors' => include(a_hash_including('message' => /Field 'baz' doesn't accept argument 'arg'/))
        )
      end
    end
  end
end
