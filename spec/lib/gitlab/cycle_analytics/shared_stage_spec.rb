require 'spec_helper'

shared_examples 'base stage' do
  ISSUES_MEDIAN = 30.minutes.to_i

  let(:stage) { described_class.new(options: { project: double }) }

  before do
    allow(stage).to receive(:project_median).and_return(1.12)
    allow_any_instance_of(Gitlab::CycleAnalytics::BaseEventFetcher).to receive(:event_result).and_return({})
  end

  it 'has the median data value' do
    expect(stage.as_json[:value]).not_to be_nil
  end

  it 'has the median data stage' do
    expect(stage.as_json[:title]).not_to be_nil
  end

  it 'has the median data description' do
    expect(stage.as_json[:description]).not_to be_nil
  end

  it 'has the title' do
    expect(stage.title).to eq(stage_name.to_s.capitalize)
  end

  it 'has the events' do
    expect(stage.events).not_to be_nil
  end
end
