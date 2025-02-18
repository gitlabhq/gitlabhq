# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::RailsSlis, feature_category: :error_budgets do
  before do
    allow(Gitlab::Graphql::KnownOperations).to receive(:default)
      .and_return(Gitlab::Graphql::KnownOperations.new(%w[foo bar]))
  end

  describe '.initialize_request_slis!' do
    let(:web_uninitialized_labels) do
      [{
        endpoint_id: "Admin::AbuseReportsController#index",
        feature_category: :insider_threat,
        request_urgency: :default
      }]
    end

    let(:web_expected_labels) do
      [
        {
          endpoint_id: "ProjectsController#index",
          feature_category: :groups_and_projects,
          request_urgency: :default
        }
      ]
    end

    let(:web_possible_labels) do
      web_expected_labels + web_uninitialized_labels
    end

    # using the actual `#known_git_endpoints` here makes sure that we keep the
    # list up to date as endpoints get removed
    let(:git_possible_labels) do
      described_class.__send__(:known_git_endpoints).map do |endpoint_id|
        a_hash_including({
          endpoint_id: endpoint_id
        })
      end
    end

    let(:api_uninitialized_labels) do
      [
        { endpoint_id: "DELETE /api/:version/admin/ci/variables/:key",
          feature_category: :ci_variables,
          request_urgency: :default }
      ]
    end

    let(:api_expected_labels) do
      [{
        endpoint_id: "GET /api/:version/version",
        feature_category: :not_owned,
        request_urgency: :default
      }]
    end

    let(:api_possible_labels) do
      api_expected_labels + api_uninitialized_labels
    end

    let(:expected_request_labels) do
      web_expected_labels + git_possible_labels + api_expected_labels
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

    it "initializes the SLI for all expected endpoints", :aggregate_failures do
      uninitialized_labels = api_uninitialized_labels + web_uninitialized_labels

      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli) do |sli_name, labelsets|
        expect(sli_name).to eq(:rails_request)
        expect(labelsets).to include(*expected_request_labels)
        expect(labelsets).not_to include(*uninitialized_labels)
      end

      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli) do |sli_name, labelsets|
        expect(sli_name).to eq(:rails_request)
        expect(labelsets).to include(*expected_request_labels)
        expect(labelsets).not_to include(*uninitialized_labels)
      end

      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli)
        .with(:graphql_query, array_including(*possible_graphql_labels)).and_call_original
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli)
        .with(:graphql_query, array_including(*possible_graphql_labels)).and_call_original

      described_class.initialize_request_slis!
    end

    context "when initializeing for limited types" do
      using RSpec::Parameterized::TableSyntax

      where(:git, :api, :web) do
        [true, false].repeated_permutation(3).to_a
      end

      with_them do
        it 'initializes only with the expected labels', :aggregate_failures do
          allow(Gitlab::Metrics::Environment).to receive(:git?).and_return(git)
          allow(Gitlab::Metrics::Environment).to receive(:api?).and_return(api)
          allow(Gitlab::Metrics::Environment).to receive(:web?).and_return(web)
          allow(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli)
          allow(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli)

          described_class.initialize_request_slis!

          if git
            expect(Gitlab::Metrics::Sli::Apdex).to have_received(:initialize_sli)
              .with(:rails_request, array_including(*git_possible_labels))
            expect(Gitlab::Metrics::Sli::ErrorRate).to have_received(:initialize_sli)
              .with(:rails_request, array_including(*git_possible_labels))
          else
            expect(Gitlab::Metrics::Sli::Apdex).not_to have_received(:initialize_sli)
              .with(:rails_request, array_including(*git_possible_labels))
            expect(Gitlab::Metrics::Sli::ErrorRate).not_to have_received(:initialize_sli)
              .with(:rails_request, array_including(*git_possible_labels))
          end

          if api
            expect(Gitlab::Metrics::Sli::Apdex).to have_received(:initialize_sli)
              .with(:rails_request, array_including(*api_expected_labels))
            expect(Gitlab::Metrics::Sli::ErrorRate).to have_received(:initialize_sli)
              .with(:rails_request, array_including(*api_expected_labels))
            expect(Gitlab::Metrics::Sli::Apdex).to have_received(:initialize_sli)
              .with(:graphql_query, array_including(*possible_graphql_labels))
          else
            expect(Gitlab::Metrics::Sli::Apdex).not_to have_received(:initialize_sli)
              .with(:rails_request, array_including(*api_expected_labels))
            expect(Gitlab::Metrics::Sli::ErrorRate).not_to have_received(:initialize_sli)
              .with(:rails_request, array_including(*api_expected_labels))
            expect(Gitlab::Metrics::Sli::Apdex).to have_received(:initialize_sli)
              .with(:graphql_query, [])
          end

          if web
            expect(Gitlab::Metrics::Sli::Apdex).to have_received(:initialize_sli)
              .with(:rails_request, array_including(*web_expected_labels))
            expect(Gitlab::Metrics::Sli::ErrorRate).to have_received(:initialize_sli)
              .with(:rails_request, array_including(*web_expected_labels))
          else
            expect(Gitlab::Metrics::Sli::Apdex).not_to have_received(:initialize_sli)
              .with(:rails_request, array_including(*web_expected_labels))
            expect(Gitlab::Metrics::Sli::ErrorRate).not_to have_received(:initialize_sli)
              .with(:rails_request, array_including(*web_expected_labels))
          end
        end
      end
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

  describe '.graphql_query_error_rate' do
    it 'returns the initialized request apdex SLI object' do
      described_class.initialize_request_slis!

      expect(described_class.graphql_query_error_rate).to be_initialized
    end
  end
end
