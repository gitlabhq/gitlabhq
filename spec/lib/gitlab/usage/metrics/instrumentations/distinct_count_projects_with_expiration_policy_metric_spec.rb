# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DistinctCountProjectsWithExpirationPolicyMetric do
  before_all do
    create(:container_expiration_policy, enabled: false)
    create(:container_expiration_policy, enabled: false, created_at: 29.days.ago)
    create(:container_expiration_policy, keep_n: nil)
    create(:container_expiration_policy, keep_n: 5, enabled: true)
    create(:container_expiration_policy, keep_n: 5, enabled: true)
    create(:container_expiration_policy, keep_n: 5, enabled: true)
    create(:container_expiration_policy, older_than: '7d')
    create(:container_expiration_policy, cadence: '14d')
    create(:container_expiration_policy, enabled: true)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', options: { enabled: false } } do
    let(:expected_value) { 1 }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', options: { enabled: false } } do
    let(:expected_value) { 2 }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', options: { keep_n: 5, enabled: true } } do
    let(:expected_value) { 3 }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', options: { cadence: '14d' } } do
    let(:expected_value) { 1 }
  end
end
