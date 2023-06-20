# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountAllCiBuildsMetric, feature_category: :continuous_integration do
  before do
    create(:ci_build, created_at: 5.days.ago)
    create(:ci_build, created_at: 1.year.ago)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 2 }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' } do
    let(:expected_value) { 1 }
  end
end
