# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::GlqlSlis, :prometheus, feature_category: :markdown do
  describe '.initialize_slis!' do
    let(:endpoint_id) { 'Glql::BaseController#execute' }
    let(:possible_glql_labels) do
      [
        { endpoint_id: endpoint_id, error_type: :query_aborted, feature_category: :code_review_workflow,
          query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: :query_aborted, feature_category: :not_owned, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: :query_aborted, feature_category: :portfolio_management,
          query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: :query_aborted, feature_category: :team_planning, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: :query_aborted, feature_category: :wiki, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: :other, feature_category: :code_review_workflow, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: :other, feature_category: :not_owned, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: :other, feature_category: :portfolio_management, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: :other, feature_category: :team_planning, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: :other, feature_category: :wiki, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: nil, feature_category: :code_review_workflow, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: nil, feature_category: :not_owned, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: nil, feature_category: :portfolio_management, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: nil, feature_category: :team_planning, query_urgency: :low },
        { endpoint_id: endpoint_id, error_type: nil, feature_category: :wiki, query_urgency: :low }
      ]
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
