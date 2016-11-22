require 'spec_helper'

shared_examples 'base stage' do
  let(:stage) { described_class.new(project: double, options: {}, stage: stage_name) }

  before do
    allow_any_instance_of(Gitlab::CycleAnalytics::MetricsFetcher).to receive(:calculate_metric).and_return(1.12)
    allow_any_instance_of(Gitlab::CycleAnalytics::BaseEvent).to receive(:event_result).and_return({})
  end

  it 'has the median data value' do
    expect(stage.median_data[:value]).not_to be_nil
  end

  it 'has the median data stage' do
    expect(stage.median_data[:title]).not_to be_nil
  end

  it 'has the median data description' do
    expect(stage.median_data[:description]).not_to be_nil
  end

  it 'has the stage' do
    expect(stage.stage).to eq(stage_name)
  end

  it 'has the events' do
    expect(stage.events).not_to be_nil
  end
end
