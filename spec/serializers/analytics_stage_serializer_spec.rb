require 'spec_helper'

describe AnalyticsStageSerializer do
  subject do
    described_class.new.represent(resource)
  end

  let(:resource) do
    Gitlab::CycleAnalytics::CodeStage.new(project: double, options: {})
  end

  before do
    allow_any_instance_of(Gitlab::CycleAnalytics::BaseStage).to receive(:median).and_return(1.12)
    allow_any_instance_of(Gitlab::CycleAnalytics::BaseEventFetcher).to receive(:event_result).and_return({})
  end

  it 'generates payload for single object' do
    expect(subject).to be_kind_of Hash
  end

  it 'contains important elements of AnalyticsStage' do
    expect(subject).to include(:title, :description, :value)
  end
end
