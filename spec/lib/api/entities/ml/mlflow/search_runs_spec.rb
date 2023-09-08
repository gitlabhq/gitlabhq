# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ml::Mlflow::SearchRuns, feature_category: :mlops do
  let_it_be(:candidates) { [build_stubbed(:ml_candidates, :with_metrics_and_params), build_stubbed(:ml_candidates)] }

  let(:next_page_token) { 'abcdef' }

  subject { described_class.new({ candidates: candidates, next_page_token: next_page_token }).as_json }

  it 'presents the candidates', :aggregate_failures do
    expect(subject[:runs].size).to eq(2)
    expect(subject.dig(:runs, 0, :info, :run_id)).to eq(candidates[0].eid.to_s)
    expect(subject.dig(:runs, 1, :info, :run_id)).to eq(candidates[1].eid.to_s)
  end

  it 'presents metrics', :aggregate_failures do
    expect(subject.dig(:runs, 0, :data, :metrics).size).to eq(candidates[0].metrics.size)
    expect(subject.dig(:runs, 1, :data, :metrics).size).to eq(0)

    presented_metric = subject.dig(:runs, 0, :data, :metrics, 0, :key)
    metric = candidates[0].metrics[0].name

    expect(presented_metric).to eq(metric)
  end

  it 'presents params', :aggregate_failures do
    expect(subject.dig(:runs, 0, :data, :params).size).to eq(candidates[0].params.size)
    expect(subject.dig(:runs, 1, :data, :params).size).to eq(0)

    presented_param = subject.dig(:runs, 0, :data, :params, 0, :key)
    param = candidates[0].params[0].name

    expect(presented_param).to eq(param)
  end
end
