# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab::Graphql::Tracers::Instrumentation integration test', :aggregate_failures, feature_category: :integrations do
  include GraphqlHelpers

  let_it_be(:user) { create(:user, username: 'instrumentation-tester') }

  describe "logging" do
    it "logs a message for each query in a request" do
      common_log_info = {
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

    it "includes errors for failing queries" do
      queries = [
        { query: graphql_query_for('brokenQuery', {}, []),
          variables: { test: "hello world" } },
        { query: graphql_query_for('currentUser', {}, ["username"]) }
      ]

      expect(Gitlab::GraphqlLogger).to receive(:info).with(a_hash_including({
        graphql_errors: [{
          "message" => "Field 'brokenQuery' doesn't exist on type 'Query'",
          "locations" => [{ "line" => 1, "column" => 3 }],
          "path" => %w[query brokenQuery],
          "extensions" => { "code" => "undefinedField", "typeName" => "Query", "fieldName" => "brokenQuery" }
        }]
      }))
      expect(Gitlab::GraphqlLogger).to receive(:info).with(hash_excluding({ graphql_errors: [] }))

      post_multiplex(queries, current_user: user)

      expect(json_response.size).to eq(2)
    end
  end

  describe "metrics" do
    let(:unknown_query_labels) do
      {
        endpoint_id: "graphql:unknown",
        feature_category: 'not_owned',
        query_urgency: :default
      }
    end

    it "tracks SLI metrics for each query" do
      expect(Gitlab::Metrics::RailsSlis.graphql_query_apdex).to receive(:increment).with({
        labels: unknown_query_labels,
        success: be_in([true, false])
      })

      expect(Gitlab::Metrics::RailsSlis.graphql_query_error_rate).to receive(:increment).with({
        labels: unknown_query_labels,
        error: false
      })

      post_graphql(graphql_query_for('echo', { 'text' => 'test' }, []))
    end

    it "does not track apdex for failed queries" do
      expect(Gitlab::Metrics::RailsSlis.graphql_query_apdex).not_to receive(:increment)

      post_graphql(graphql_query_for('brokenQuery', {}, []))
    end

    it "tracks errors for failed queries" do
      queries = [
        { query: graphql_query_for('brokenQuery', {}, []),
          variables: { test: "hello world" } },
        { query: graphql_query_for('currentUser', {}, ["username"]) }
      ]

      expect(Gitlab::Metrics::RailsSlis.graphql_query_error_rate).to receive(:increment).with({
        labels: unknown_query_labels,
        error: false
      })

      expect(Gitlab::Metrics::RailsSlis.graphql_query_error_rate).to receive(:increment).with({
        labels: unknown_query_labels,
        error: true
      })

      post_multiplex(queries, current_user: user)

      expect(json_response.size).to eq(2)
    end
  end

  it "recognizes known queries from our frontend" do
    query = <<~GQL
      query abuseReportQuery { currentUser{ username} }
    GQL

    expect(Gitlab::Metrics::RailsSlis.graphql_query_apdex).to receive(:increment).with({
      labels: {
        endpoint_id: "graphql:abuseReportQuery",
        feature_category: 'not_owned',
        query_urgency: :default
      },
      success: be_in([true, false])
    })

    expect(Gitlab::GraphqlLogger).to receive(:info).with(a_hash_including({
      "meta.caller_id" => "graphql:abuseReportQuery"
    }))

    post_graphql(query, current_user: user)
  end
end
