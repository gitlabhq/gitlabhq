require 'spec_helper'

describe AnalyticsStageSerializer do
  let(:serializer) do
    described_class
      .new.represent(resource)
  end

  let(:json) { serializer.as_json }
  let(:resource) { Gitlab::CycleAnalytics::CodeStage.new(project: double, options: {}) }

  before do
    allow_any_instance_of(Gitlab::CycleAnalytics::BaseStage).to receive(:median).and_return(1.12)
    allow_any_instance_of(Gitlab::CycleAnalytics::BaseEventFetcher).to receive(:event_result).and_return({})
  end

  it 'it generates payload for single object' do
    expect(json).to be_kind_of Hash
  end

  it 'contains important elements of AnalyticsStage' do
    expect(json).to include(:title, :description, :value)
  end
end
