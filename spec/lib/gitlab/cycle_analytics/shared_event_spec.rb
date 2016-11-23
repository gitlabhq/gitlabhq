require 'spec_helper'

shared_examples 'default query config' do
  let(:fetcher) do
    Gitlab::CycleAnalytics::MetricsFetcher.new(project: create(:empty_project),
                                               from: 1.day.ago,
                                               branch: nil)
  end

  let(:event) { described_class.new(fetcher: fetcher, stage: stage_name, options: {}) }

  it 'has the start attributes' do
    expect(event.start_time_attrs).not_to be_nil
  end

  it 'has the stage attribute' do
    expect(event.stage).not_to be_nil
  end

  it 'has the end attributes' do
    expect(event.end_time_attrs).not_to be_nil
  end

  it 'has the projection attributes' do
    expect(event.projections).not_to be_nil
  end
end
