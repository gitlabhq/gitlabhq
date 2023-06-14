# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountSnippetsMetric, feature_category: :service_ping do
  before_all do
    create(:personal_snippet, created_at: 5.days.ago)
    create(:personal_snippet, created_at: 1.year.ago)

    create(:project_snippet, created_at: 1.year.ago)
    create(:project_snippet, created_at: 5.days.ago)
  end

  context 'with a time_frame of 28 days' do
    let(:expected_value) { 2 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' }
  end

  context 'with a timeframe of all' do
    let(:expected_value) { 4 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
  end
end
