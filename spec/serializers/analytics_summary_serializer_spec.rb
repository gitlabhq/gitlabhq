require 'spec_helper'

describe AnalyticsSummarySerializer do
  let(:serializer) do
    described_class
      .new.represent(resource)
  end

  let(:json) { serializer.as_json }
  let(:project) { create(:empty_project) }
  let(:resource) { Gitlab::CycleAnalytics::Summary::Issue.new(project: double, from: 1.day.ago) }

  before do
    allow_any_instance_of(Gitlab::CycleAnalytics::Summary::Issue).to receive(:value).and_return(1.12)
  end

  it 'it generates payload for single object' do
    expect(json).to be_an_instance_of Hash
  end

  it 'contains important elements of AnalyticsStage' do
    expect(json).to include(:title, :value)
  end
end
