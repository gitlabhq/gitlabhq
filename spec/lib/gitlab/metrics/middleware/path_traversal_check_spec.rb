# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Middleware::PathTraversalCheck, feature_category: :shared do
  describe '.initialize_slis!' do
    subject(:initialize_slis!) { described_class.initialize_slis! }

    it 'initializes all metrics' do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli)
        .with(*described_class::DURATION_APDEX_SLI_DEFINITION)

      initialize_slis!
    end
  end

  describe '.increment' do
    let(:labels) { { request_rejected: true } }
    let(:duration) { 1.5 }

    subject(:increment) { described_class.increment(labels: labels, duration: 1.5) }

    it 'increments the apdex' do
      expect(::Gitlab::Metrics::Sli::Apdex[described_class::DURATION_APDEX_NAME]).to receive(:increment)
        .with(labels: labels.merge(described_class::DURATION_APDEX_FEATURE_CATEGORY), success: false)

      increment
    end
  end
end
