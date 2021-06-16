# frozen_string_literal: true

RSpec.shared_examples 'a correct instrumented metric value' do |params|
  let(:time_frame) { params[:time_frame] }
  let(:options) { params[:options] }
  let(:metric) { described_class.new(time_frame: time_frame, options: options) }

  before do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
  end

  it 'has correct value' do
    expect(metric.value).to eq(expected_value)
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
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
  end

  it 'has correct generate query' do
    expect(metric.to_sql).to eq(expected_query)
  end
end

RSpec.shared_examples 'a correct instrumented metric value and query' do |params|
  it_behaves_like 'a correct instrumented metric value', params
  it_behaves_like 'a correct instrumented metric query', params
end
