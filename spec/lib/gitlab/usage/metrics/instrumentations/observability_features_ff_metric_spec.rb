# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ObservabilityFeaturesFfMetric, feature_category: :product_analytics do
  context 'with FF enabled globally' do
    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', data_source: 'database' } do
      let(:expected_value) { -1 }
    end
  end

  # stub_feature_flags: disabled is required for Feature#group_ids_for to work correctly
  context 'with FF enabled for specific groups', stub_feature_flags: false do
    before do
      stub_feature_flags(observability_features: create_list(:group, 3))
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', data_source: 'database' } do
      let(:expected_value) { 3 }
    end
  end

  context 'with FF disabled' do
    before do
      stub_feature_flags(observability_features: false)
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', data_source: 'database' } do
      let(:expected_value) { 0 }
    end
  end
end
