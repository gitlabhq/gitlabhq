# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCiInternalPipelinesMetric,
feature_category: :service_ping do
  let_it_be(:ci_pipeline_1) { create(:ci_pipeline, source: :external) }
  let_it_be(:ci_pipeline_2) { create(:ci_pipeline, source: :push) }

  let(:expected_value) { 1 }
  let(:expected_query) do
    'SELECT COUNT("ci_pipelines"."id") FROM "ci_pipelines" ' \
      'WHERE ("ci_pipelines"."source" IN (1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15) ' \
      'OR "ci_pipelines"."source" IS NULL)'
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }

  context 'on Gitlab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    let(:expected_value) { -1 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
  end
end
