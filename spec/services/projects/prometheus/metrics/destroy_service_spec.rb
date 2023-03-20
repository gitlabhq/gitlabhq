# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Prometheus::Metrics::DestroyService, feature_category: :metrics do
  let(:metric) { create(:prometheus_metric) }

  subject { described_class.new(metric) }

  it 'destroys metric' do
    subject.execute

    expect(PrometheusMetric.find_by(id: metric.id)).to be_nil
  end
end
