# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCiInternalPipelinesMetric,
  feature_category: :service_ping do
  let_it_be(:ci_pipeline_1) { create(:ci_pipeline, source: :external, created_at: 3.days.ago) }
  let_it_be(:ci_pipeline_2) { create(:ci_pipeline, source: :push, created_at: 3.days.ago) }
  let_it_be(:old_pipeline) { create(:ci_pipeline, source: :push, created_at: 2.months.ago) }
  let_it_be(:expected_value) { 2 }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }

  context 'for monthly counts' do
    let_it_be(:expected_value) { 1 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' }
  end

  context 'on SaaS', :saas do
    let_it_be(:expected_value) { -1 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' }
  end
end
