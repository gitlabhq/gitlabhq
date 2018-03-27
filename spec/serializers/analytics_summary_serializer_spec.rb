require 'spec_helper'

describe AnalyticsSummarySerializer do
  subject do
    described_class.new.represent(resource)
  end

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  let(:resource) do
    Gitlab::CycleAnalytics::Summary::Issue
      .new(project: double, from: 1.day.ago, current_user: user)
  end

  before do
    allow_any_instance_of(Gitlab::CycleAnalytics::Summary::Issue)
      .to receive(:value).and_return(1.12)
  end

  it 'it generates payload for single object' do
    expect(subject).to be_kind_of Hash
  end

  it 'contains important elements of AnalyticsStage' do
    expect(subject).to include(:title, :value)
  end
end
