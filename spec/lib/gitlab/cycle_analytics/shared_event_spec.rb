require 'spec_helper'

shared_examples 'default query config' do
  let(:fetcher) do
    Gitlab::CycleAnalytics::MetricsFetcher.new(project: create(:empty_project),
                                               from: 1.day.ago,
                                               branch: nil,
                                               stage: stage_name)
  end

  let(project)
  let(:event) { described_class.new(project: project, stage: stage_name, options: {}) }

  it 'has the stage attribute' do
    expect(event.name).not_to be_nil
  end

  it 'has the projection attributes' do
    expect(event.projections).not_to be_nil
  end
end
