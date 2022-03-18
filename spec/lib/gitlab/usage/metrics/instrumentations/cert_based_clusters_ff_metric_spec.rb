# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CertBasedClustersFfMetric do
  context 'with FF enabled' do
    it_behaves_like 'a correct instrumented metric value', { time_frame: '7d', data_source: 'database' } do
      let(:expected_value) { true }
    end
  end

  context 'with FF disabled' do
    before do
      stub_feature_flags(certificate_based_clusters: false)
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: '7d', data_source: 'database' } do
      let(:expected_value) { false }
    end
  end
end
