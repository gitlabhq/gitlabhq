# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::GlqlSlis, feature_category: :error_budgets do
  before do
    allow(Gitlab::Graphql::KnownOperations).to receive(:default)
      .and_return(Gitlab::Graphql::KnownOperations.new(%w[foo bar]))
  end

  describe '.initialize_slis!' do
    let(:possible_glql_labels) do
      ['graphql:foo', 'graphql:bar', 'graphql:unknown'].map do |endpoint_id|
        {
          endpoint_id: endpoint_id,
          feature_category: nil,
          query_urgency: ::Gitlab::EndpointAttributes::DEFAULT_URGENCY.name
        }
      end
    end

    it 'initializes Apdex SLIs for glql' do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
        :glql,
        array_including(possible_glql_labels)
      )

      described_class.initialize_slis!
    end

    it 'initializes ErrorRate SLIs for glql' do
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(
        :glql,
        array_including(possible_glql_labels)
      )

      described_class.initialize_slis!
    end
  end

  describe '.record_apdex' do
    it 'calls increment on success SLI' do
      expect(Gitlab::Metrics::Sli::Apdex[:glql]).to receive(:increment).with(
        labels: { feature_category: :foo },
        success: true
      )

      described_class.record_apdex(labels: { feature_category: :foo }, success: true)
    end
  end

  describe '.record_error' do
    it 'calls increment on the error rate SLI' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:glql]).to receive(:increment)

      described_class.record_error(labels: { feature_category: :foo }, error: true)
    end
  end
end
