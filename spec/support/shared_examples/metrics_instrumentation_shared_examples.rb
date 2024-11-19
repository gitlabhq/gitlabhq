# frozen_string_literal: true

RSpec.shared_examples 'a correct instrumented metric value' do |params|
  let(:time_frame) { params[:time_frame] }
  let(:options) { params[:options] }
  let(:events) { params.slice(:events) }
  let(:metric) { described_class.new({ time_frame: time_frame, options: options }.merge(events)) }

  around do |example|
    freeze_time { example.run }
  end

  before do
    if metric.respond_to?(:relation, true) && metric.send(:relation).respond_to?(:connection)
      allow(metric.send(:relation).connection).to receive(:transaction_open?).and_return(false)
    end
  end

  it 'has correct value' do
    metric_value = metric.value

    if metric_value.is_a?(Float)
      expect(metric_value).to be_within(0.000001).of(expected_value)
    else
      expect(metric_value).to eq(expected_value)
    end
  end
end

RSpec.shared_examples 'a correct instrumented metric query' do |params|
  let(:time_frame) { params[:time_frame] }
  let(:options) { params[:options] }
  let(:metric) { described_class.new(time_frame: time_frame, options: options) }

  around do |example|
    freeze_time { example.run }
  end

  before do
    if metric.respond_to?(:relation, true) && metric.send(:relation).respond_to?(:connection)
      allow(metric.send(:relation).connection).to receive(:transaction_open?).and_return(false)
    end
  end

  it 'has correct generate query' do
    expect(metric.instrumentation).to eq(expected_query)
  end
end

RSpec.shared_examples 'a correct instrumented database query execution value' do |params|
  let(:time_frame) { params[:time_frame] }
  let(:options) { params[:options] }
  let(:metric) { described_class.new(time_frame: time_frame, options: options) }

  around do |example|
    freeze_time { example.run }
  end

  before do
    allow(metric.relation).to receive(:transaction_open?).and_return(false)
  end

  it 'returns correct value' do
    query_result = metric.relation.connection.execute(metric.instrumentation).to_a.first.each_value.first
    expect(query_result).to eq(expected_value)
  end
end

RSpec.shared_examples 'a correct instrumented metric value and query' do |params|
  it_behaves_like 'a correct instrumented metric value', params
  it_behaves_like 'a correct instrumented metric query', params
end
