# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Metrics::RailsSlis do
  # Limit what routes we'll initialize so we don't have to load the entire thing
  before do
    api_route = API::API.routes.find do |route|
      API::Base.endpoint_id_for_route(route) == "GET /api/:version/version"
    end

    allow(Gitlab::RequestEndpoints).to receive(:all_api_endpoints).and_return([api_route])
    allow(Gitlab::RequestEndpoints).to receive(:all_controller_actions).and_return([[ProjectsController, 'index']])
    allow(Gitlab::Graphql::KnownOperations).to receive(:default).and_return(Gitlab::Graphql::KnownOperations.new(%w(foo bar)))
  end

  describe '.initialize_request_slis!' do
    let(:possible_labels) do
      [
        {
          endpoint_id: "GET /api/:version/version",
          feature_category: :not_owned,
          request_urgency: :default
        },
        {
          endpoint_id: "ProjectsController#index",
          feature_category: :projects,
          request_urgency: :default
        }
      ]
    end

    let(:possible_graphql_labels) do
      ['graphql:foo', 'graphql:bar', 'graphql:unknown'].map do |endpoint_id|
        {
          endpoint_id: endpoint_id,
          feature_category: nil,
          query_urgency: ::Gitlab::EndpointAttributes::DEFAULT_URGENCY.name
        }
      end
    end

    it "initializes the SLI for all possible endpoints if they weren't", :aggregate_failures do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(:rails_request, array_including(*possible_labels)).and_call_original
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(:graphql_query, array_including(*possible_graphql_labels)).and_call_original
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(:rails_request, array_including(*possible_labels)).and_call_original

      described_class.initialize_request_slis!
    end

    it "initializes the SLI for all possible endpoints if they weren't given error rate feature flag is disabled", :aggregate_failures do
      stub_feature_flags(gitlab_metrics_error_rate_sli: false)

      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(:rails_request, array_including(*possible_labels)).and_call_original
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(:graphql_query, array_including(*possible_graphql_labels)).and_call_original
      expect(Gitlab::Metrics::Sli::ErrorRate).not_to receive(:initialize_sli)

      described_class.initialize_request_slis!
    end
  end

  describe '.request_apdex' do
    it 'returns the initialized request apdex SLI object' do
      described_class.initialize_request_slis!

      expect(described_class.request_apdex).to be_initialized
    end
  end

  describe '.request_error' do
    it 'returns the initialized request error rate SLI object' do
      described_class.initialize_request_slis!

      expect(described_class.request_error_rate).to be_initialized
    end
  end

  describe '.graphql_query_apdex' do
    it 'returns the initialized request apdex SLI object' do
      described_class.initialize_request_slis!

      expect(described_class.graphql_query_apdex).to be_initialized
    end
  end
end
