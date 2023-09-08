# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ml::Mlflow::GetRun, feature_category: :mlops do
  let_it_be(:candidate) { build(:ml_candidates, :with_metrics_and_params) }

  subject { described_class.new(candidate).as_json }

  it 'has run key' do
    expect(subject).to have_key(:run)
  end

  it 'has the id' do
    expect(subject.dig(:run, :info, :run_id)).to eq(candidate.eid.to_s)
  end

  it 'presents the metrics' do
    expect(subject.dig(:run, :data, :metrics).size).to eq(candidate.metrics.size)
  end

  it 'presents metrics correctly' do
    presented_metric = subject.dig(:run, :data, :metrics)[0]
    metric = candidate.metrics[0]

    expect(presented_metric[:key]).to eq(metric.name)
    expect(presented_metric[:value]).to eq(metric.value)
    expect(presented_metric[:timestamp]).to eq(metric.tracked_at)
    expect(presented_metric[:step]).to eq(metric.step)
  end

  it 'presents the params' do
    expect(subject.dig(:run, :data, :params).size).to eq(candidate.params.size)
  end

  it 'presents params correctly' do
    presented_param = subject.dig(:run, :data, :params)[0]
    param = candidate.params[0]

    expect(presented_param[:key]).to eq(param.name)
    expect(presented_param[:value]).to eq(param.value)
  end

  context 'when candidate has no metrics' do
    before do
      allow(candidate).to receive(:metrics).and_return([])
    end

    it 'returns empty data' do
      expect(subject.dig(:run, :data, :metrics)).to be_empty
    end
  end

  context 'when candidate has no params' do
    before do
      allow(candidate).to receive(:params).and_return([])
    end

    it 'data is empty' do
      expect(subject.dig(:run, :data, :params)).to be_empty
    end
  end
end
