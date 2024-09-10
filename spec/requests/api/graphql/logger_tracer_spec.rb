# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab::Graphql::Tracers::Logger integration test', :aggregate_failures, feature_category: :integrations do
  include GraphqlHelpers

  let_it_be(:user) { create(:user, username: 'instrumentation-tester') }

  describe "logging" do
    let_it_be(:common_log_info) do
      {
        "correlation_id" => be_a(String),
        :trace_type => "execute_query",
        :query_fingerprint => be_a(String),
        :duration_s => be_a(Float),
        :operation_fingerprint => be_a(String),
        "meta.remote_ip" => "127.0.0.1",
        "meta.feature_category" => "not_owned",
        "meta.user" => "instrumentation-tester",
        "meta.user_id" => user.id,
        "meta.client_id" => "user/#{user.id}",
        "query_analysis.duration_s" => be_a(Float),
        "meta.caller_id" => "graphql:unknown"
      }
    end

    it "logs a message for each query in a request" do
      expect(Gitlab::GraphqlLogger).to receive(:info).with(a_hash_including({
        **common_log_info,
        variables: "{\"test\"=>\"hello world\"}",
        query_string: "{ echo(text: \"$test\") }"
      }))

      expect(Gitlab::GraphqlLogger).to receive(:info).with(a_hash_including({
        **common_log_info,
        variables: "{}",
        query_string: "{ currentUser{\n  username\n}\n }"
      }))

      queries = [
        { query: graphql_query_for('echo', { 'text' => '$test' }, []),
          variables: { test: "hello world" } },
        { query: graphql_query_for('currentUser', {}, ["username"]) }
      ]

      post_multiplex(queries, current_user: user)

      expect(json_response.size).to eq(2)
    end

    context "with a mutation query" do
      let_it_be_with_reload(:package) { create(:package) }
      let(:project) { package.project }

      let(:query) do
        <<~GQL
          errors
        GQL
      end

      let(:id) { package.to_global_id.to_s }
      let(:params) { { id: id } }
      let(:mutation) { graphql_mutation(:destroy_package, params, query) }

      let(:expected_variables) { "{\"destroyPackageInput\"=>{\"id\"=>\"#{id}\"}}" }
      let(:sanitized_mutation_query_string) do
        "mutation {\n  destroyPackage(input: {id: \"<REDACTED>\"}) {\n    errors\n  }\n}"
      end

      it "sanitizes the query string" do
        expect(Gitlab::GraphqlLogger).to receive(:info).with(a_hash_including({
          **common_log_info,
          variables: expected_variables,
          query_string: sanitized_mutation_query_string
        }))

        post_graphql_mutation(mutation, current_user: user)
      end
    end
  end
end
